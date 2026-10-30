from pathlib import Path
from collections import deque
from PIL import Image

INPUT_DIR = Path("assets/images/words_compressed")
OUTPUT_DIR = Path("assets/images/words")

# Semakin kecil, semakin selektif.
# 245 artinya hanya putih/nyaris putih yang dihapus.
WHITE_THRESHOLD = 245

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

SUPPORTED_EXTENSIONS = [".png", ".jpg", ".jpeg", ".webp"]


def is_near_white(pixel):
    r, g, b, a = pixel
    return a > 0 and r >= WHITE_THRESHOLD and g >= WHITE_THRESHOLD and b >= WHITE_THRESHOLD


def remove_connected_white_background(image):
    image = image.convert("RGBA")
    pixels = image.load()

    width, height = image.size
    visited = set()
    queue = deque()

    # Masukkan pixel tepi gambar sebagai titik awal.
    # Ini penting supaya yang dihapus hanya background putih
    # yang tersambung ke pinggir gambar, bukan putih di mata/gigi/objek.
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))

    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()

        if (x, y) in visited:
            continue

        visited.add((x, y))

        if not (0 <= x < width and 0 <= y < height):
            continue

        current_pixel = pixels[x, y]

        if not is_near_white(current_pixel):
            continue

        # Ubah background putih menjadi transparan
        r, g, b, a = current_pixel
        pixels[x, y] = (r, g, b, 0)

        # Cek tetangga kiri, kanan, atas, bawah
        queue.append((x + 1, y))
        queue.append((x - 1, y))
        queue.append((x, y + 1))
        queue.append((x, y - 1))

    return image


def main():
    files = [
        file for file in INPUT_DIR.iterdir()
        if file.suffix.lower() in SUPPORTED_EXTENSIONS
    ]

    if not files:
        print("Tidak ada gambar ditemukan di folder:", INPUT_DIR)
        return

    print(f"Memproses {len(files)} gambar...")

    for file in files:
        try:
            image = Image.open(file)
            result = remove_connected_white_background(image)

            output_path = OUTPUT_DIR / f"{file.stem}.png"
            result.save(output_path, "PNG")

            print(f"Berhasil: {file.name} -> {output_path.name}")
        except Exception as e:
            print(f"Gagal memproses {file.name}: {e}")

    print("Selesai.")
    print("Output ada di:", OUTPUT_DIR)


if __name__ == "__main__":
    main()