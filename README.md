# Julia Set Generator

A simple Zig-based program that renders a time-evolving Julia set and outputs individual frames as `.ppm` images. You can convert them into an MP4 animation using FFmpeg.

---

## 🧰 Dependencies

- **[Zig](https://ziglang.org/)** – To build and run the program  
- **[FFmpeg](https://ffmpeg.org/)** – To convert the frames into an MP4 video  

---

## 🚀 How to Run

### Debug Mode
```bash
zig build run
```
### Release Mode
```bash
zig build -Doptimize=ReleaseFast run
```

## Convert ppm frames to MP4

```bash
cd frames
ffmpeg -framerate 60 -i frame_%04d.ppm -vf "scale=1920:1080" -pix_fmt yuv420p out.mp4

```
