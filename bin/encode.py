import base64
import sys

def encode_base64(input_string):
    # Encode the input string to Base64
    encoded_bytes = base64.b64encode(input_string.encode('utf-8'))
    encoded_string = encoded_bytes.decode('utf-8')
    return encoded_string

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 encode.py 'string_to_encode'")
        sys.exit(1)

    input_string = sys.argv[1]
    encoded_output = encode_base64(input_string)
    print(encoded_output)
