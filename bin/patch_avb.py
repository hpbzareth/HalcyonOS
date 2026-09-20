import sys

def replace_hex(input_file, replacements):
    with open(input_file, 'rb') as f:
        content = f.read()

    for old_hex, new_hex in replacements:
        old_bytes = bytes.fromhex(old_hex)
        new_bytes = bytes.fromhex(new_hex)
        content = content.replace(old_bytes, new_bytes)

    with open(input_file, 'wb') as f:
        f.write(content)

    print(f"Patch AVB/VBMETA successful in {input_file}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 patch.py <file_need_to_patch.img>")
        sys.exit(1)

    input_file = sys.argv[1]
    replacements = [
        ('0000000000617662746F6F6C20312E322E30', '0300000000617662746F6F6C20312E322E30'),
        ('0000000000617662746F6F6C20312E312E30', '0200000000617662746F6F6C20312E312E30')
    ]

    replace_hex(input_file, replacements)
