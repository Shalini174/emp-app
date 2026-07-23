import os
import sys
import json
import re
from dotenv import load_dotenv
from anthropic import Anthropic
from anthropic.types import MessageParam

load_dotenv()

# --- Dynamic Configuration Retrieval ---
ENV_PROGRAM = os.getenv("PROGRAM_NAME", "PAYPROC")
rules_file = "COBOL_Static_Analysis_Rules.txt"
program_name = f"{ENV_PROGRAM}.cbl"

client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))


def extract_jcl_dd_allocations(jcl_content: str, prog_name: str) -> list:
    system_prompt = f"""
    You are a mainframe JCL expert. Analyze the provided JCL.
    Find the EXEC step that runs PGM={prog_name.replace('.cbl', '')}.
    Extract all dataset allocations (DD statements).
    Return a JSON array with keys: dd_name, dsn, disp, lrecl.
    Respond ONLY with valid JSON.
    """
    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=4096,
        system=system_prompt,
        messages=[MessageParam(role="user", content=jcl_content)]
    )
    cleaned = response.content[0].text.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.split("```")[1]
        if cleaned.startswith("json"):
            cleaned = cleaned[4:]
    try:
        res = json.loads(cleaned.strip())
        return res if isinstance(res, list) else res.get("datasets", [])
    except Exception:
        return []


def heal_cobol_fd_section(cobol_content: str, file_specs: list) -> str:
    system_prompt = """
    You are an autonomous COBOL DevOps agent.
    Task: Match FD names to DD names from the ground-truth specs provided.
    For any FD entry whose declared length does not match its 'actual_lrecl',
    output SEARCH/REPLACE blocks that surgically correct ONLY:
      - the RECORD CONTAINS clause (if present), and
      - the specific PIC clauses in the corresponding 01-level record layout
        that need to change to make the total length match 'actual_lrecl'.

    Format every edit strictly as:
    <<<<<<< SEARCH
    [Exact original lines from source code to replace]
    =======
    [Corrected lines adhering strictly to 8-72 column alignment]
    >>>>>>>

    Rules:
    1. Do NOT touch any line outside the FD/01-level entries that actually need
       a length correction. Do not reformat, reindent, or rewrite unrelated code.
    2. Apply the smallest possible change per violation.
    3. Keep standard COBOL fixed format (columns 8-72).
    4. If an FD's length already matches its actual_lrecl, do not emit any block for it.
    5. If nothing needs correcting, output nothing at all — no blocks, no commentary.
    6. Output ONLY the search/replace blocks. No explanations, no markdown wrappers.
    """
    user_content = f"Ground-Truth Specs:\n{json.dumps(file_specs)}\n\nCOBOL Code:\n{cobol_content}"

    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=4096,
        temperature=0.0,
        system=system_prompt,
        messages=[MessageParam(role="user", content=user_content)]
    )

    patch_text = response.content[0].text.strip()

    if not patch_text or "<<<<<<< SEARCH" not in patch_text:
        return cobol_content

    return apply_search_replace_patches(cobol_content, patch_text)


def static_analysis_check(cobol_code: str) -> tuple[str, str]:
    if not os.path.exists(rules_file):
        print(f"[WARN] Rules file '{rules_file}' not found. Skipping static analysis rule check.")
        return cobol_code, cobol_code

    with open(rules_file, "r", encoding="utf-8") as f:
        z = f.read()

    static_analysis_prompt = """You are an expert IBM Mainframe COBOL static analysis specialist.
Analyze the provided COBOL source code against the static analysis rules.
Do NOT regenerate the entire COBOL file. Instead, output ONLY Search & Replace blocks for lines that violate rules.

Format every edit strictly as:
<<<<<<< SEARCH
[Exact original lines from source code to replace]
=======
[Corrected lines adhering strictly to 8-72 column alignment]
>>>>>>>

Rules to strictly follow:
1. Preserve exact line order. Fix violations IN-PLACE right where they occur in the original code.
2. Apply the smallest possible change. Do not move statements to higher paragraphs.
3. Keep standard COBOL fixed format (columns 8-72).
4. Output ONLY the search/replace blocks. No explanations, no markdown wrappers outside blocks.
"""

    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=8096,
        temperature=0.0,
        system=[
            {
                "type": "text",
                "text": static_analysis_prompt
            },
            {
                "type": "text",
                "text": f"STATIC ANALYSIS RULES:\n{z}",
                "cache_control": {"type": "ephemeral"}
            }
        ],
        messages=[MessageParam(role="user", content=f"COBOL Source:\n{cobol_code}")]
    )

    patch_text = response.content[0].text.strip()
    modified_code = apply_search_replace_patches(cobol_code, patch_text)
    return cobol_code, modified_code


def apply_search_replace_patches(original_code: str, patch_text: str) -> str:
    uses_crlf = '\r\n' in original_code

    working_code = original_code.replace('\xa0', ' ').replace('\r\n', '\n')
    patch_text = patch_text.replace('\xa0', ' ').replace('\r\n', '\n')

    pattern = re.compile(r"<<<<<<< SEARCH\n(.*?)\n=======\n(.*?)\n>>>>>>>", re.DOTALL)
    matches = pattern.findall(patch_text)

    updated_code = working_code
    any_patch_applied = False

    for search_block, replace_block in matches:
        if search_block in updated_code:
            updated_code = updated_code.replace(search_block, replace_block, 1)
            any_patch_applied = True
            continue

        search_lines = [line.strip() for line in search_block.strip().splitlines() if line.strip()]
        if not search_lines:
            continue

        orig_lines = updated_code.splitlines()
        for i in range(len(orig_lines) - len(search_lines) + 1):
            candidate_stripped = [orig_lines[i + j].strip() for j in range(len(search_lines))]
            if candidate_stripped == search_lines:
                replace_lines = replace_block.splitlines()
                orig_lines[i: i + len(search_lines)] = replace_lines
                updated_code = "\n".join(orig_lines)
                any_patch_applied = True
                break

    if not any_patch_applied:
        return original_code

    if uses_crlf:
        updated_code = updated_code.replace('\n', '\r\n')

    return updated_code


def diff_diagnostic(original: str, modified: str) -> dict:
    orig_lines = original.splitlines()
    mod_lines = modified.splitlines()

    real_changes = []
    noise_changes = []

    max_len = max(len(orig_lines), len(mod_lines))
    for i in range(max_len):
        o = orig_lines[i] if i < len(orig_lines) else None
        m = mod_lines[i] if i < len(mod_lines) else None

        if o == m:
            continue
        if o is None or m is None:
            real_changes.append((i, o, m))
            continue
        if o.strip() == m.strip():
            noise_changes.append((i, o, m))
        else:
            real_changes.append((i, o, m))

    return {
        "total_diff_lines": len(real_changes) + len(noise_changes),
        "real_changes": len(real_changes),
        "noise_changes": len(noise_changes),
    }


def run_pipeline():
    cobol_file_path = os.path.join("src", program_name)

    if not os.path.exists(cobol_file_path):
        print(f"[ERROR] Source file not found: {cobol_file_path}")
        sys.exit(1)

    with open(cobol_file_path, "r", encoding="utf-8", errors="ignore") as f:
        original_code = f.read()

    # 1. Run Static Analysis check
    print(f"[INFO] Running static analysis check on local workspace file: {cobol_file_path}")
    _, modified_code = static_analysis_check(original_code)

    # 2. Look for matching JCL locally
    clean_name = program_name.replace('.cbl', '').upper().strip()
    final_code = modified_code
    jcl_content, jcl_path = None, None

    jcl_dir = "jcl"
    if os.path.exists(jcl_dir) and os.path.isdir(jcl_dir):
        for file_name in os.listdir(jcl_dir):
            if file_name.upper().endswith(".JCL"):
                path = os.path.join(jcl_dir, file_name)
                try:
                    with open(path, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                    if f"EXEC PGM={clean_name}" in content.upper():
                        jcl_content, jcl_path = content, path
                        break
                except Exception as e:
                    print(f"[WARN] Error reading JCL file '{path}': {e}")

    # 3. Perform FD healing if matching JCL is found
    if jcl_content:
        print(f"[INFO] Found matching local JCL at '{jcl_path}'. Performing FD section healing...")
        jcl_datasets = extract_jcl_dd_allocations(jcl_content, program_name)
        file_specs = [{"dd_name": ds.get("dd_name"), "actual_lrecl": ds.get("lrecl") or 80} for ds in jcl_datasets]
        final_code = heal_cobol_fd_section(modified_code, file_specs)
    else:
        print(f"[INFO] No matching local JCL found for PGM={clean_name}. Proceeding with static analysis fixes.")

    # 4. Evaluate diff & update local workspace file
    diag = diff_diagnostic(original_code, final_code)

    if diag["real_changes"] == 0:
        print("[INFO] Static Analysis passed with no changes needed. Local file untouched.")
        sys.exit(0)

    # Apply fixes in-place
    print(f"[INFO] {diag['real_changes']} real change(s) detected! Overwriting local file: {cobol_file_path}")
    with open(cobol_file_path, "w", encoding="utf-8", newline="") as f:
        f.write(final_code)

    print("[INFO] Static analysis corrections successfully applied to local repository file.")
    sys.exit(0)


if __name__ == "__main__":
    run_pipeline()
