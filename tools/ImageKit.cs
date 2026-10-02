// Small image helpers used by tools/process-images.ps1 (System.Drawing, no external dependencies).
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class ImageKit
{
    static ImageCodecInfo JpegCodec()
    {
        foreach (var c in ImageCodecInfo.GetImageEncoders()) if (c.MimeType == "image/jpeg") return c;
        return null;
    }

    public static void SaveJpeg(Bitmap bmp, string path, long quality)
    {
        var p = new EncoderParameters(1);
        p.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, quality);
        bmp.Save(path, JpegCodec(), p);
    }

    public static Bitmap Resize(Image src, int w, int h)
    {
        var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.CompositingQuality = CompositingQuality.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            using (var ia = new ImageAttributes())
            {
                ia.SetWrapMode(WrapMode.TileFlipXY);
                g.DrawImage(src, new Rectangle(0, 0, w, h), 0, 0, src.Width, src.Height, GraphicsUnit.Pixel, ia);
            }
        }
        return bmp;
    }

    /// Resize a photo to a target width and write a JPEG. Returns the output height.
    public static int ResizeJpeg(string src, string dest, int width, long quality)
    {
        using (var img = Image.FromFile(src))
        {
            int w = Math.Min(width, img.Width);
            int h = (int)Math.Round(img.Height * (w / (double)img.Width));
            using (var bmp = Resize(img, w, h))
            using (var flat = new Bitmap(w, h, PixelFormat.Format24bppRgb))
            {
                using (var g = Graphics.FromImage(flat)) g.DrawImage(bmp, 0, 0, w, h);
                SaveJpeg(flat, dest, quality);
            }
            return h;
        }
    }

    /// Removes the white background connected to the image border (flood fill), with a soft edge,
    /// then trims to content. Interior whites (van highlights, clouds) are preserved.
    public static Bitmap CutOutWhite(string src, int threshold, int pad)
    {
        Bitmap bmp;
        using (var img = Image.FromFile(src)) { bmp = new Bitmap(img.Width, img.Height, PixelFormat.Format32bppArgb); using (var g = Graphics.FromImage(bmp)) g.DrawImage(img, 0, 0, img.Width, img.Height); }
        int W = bmp.Width, H = bmp.Height;
        var rect = new Rectangle(0, 0, W, H);
        var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        var px = new byte[W * H * 4];
        Marshal.Copy(data.Scan0, px, 0, px.Length);

        Func<int, int> minCh = i => Math.Min(px[i * 4], Math.Min(px[i * 4 + 1], px[i * 4 + 2]));
        var bg = new bool[W * H];
        var q = new Queue<int>();
        for (int x = 0; x < W; x++) { q.Enqueue(x); q.Enqueue((H - 1) * W + x); }
        for (int y = 0; y < H; y++) { q.Enqueue(y * W); q.Enqueue(y * W + W - 1); }
        while (q.Count > 0)
        {
            int i = q.Dequeue();
            if (bg[i] || minCh(i) < threshold) continue;
            bg[i] = true;
            int x = i % W, y = i / W;
            if (x > 0) q.Enqueue(i - 1); if (x < W - 1) q.Enqueue(i + 1);
            if (y > 0) q.Enqueue(i - W); if (y < H - 1) q.Enqueue(i + W);
        }
        for (int i = 0; i < W * H; i++)
        {
            if (bg[i]) { px[i * 4 + 3] = 0; continue; }
            // soft edge: pixels touching the background fade by their whiteness
            int x = i % W, y = i / W;
            bool edge = (x > 0 && bg[i - 1]) || (x < W - 1 && bg[i + 1]) || (y > 0 && bg[i - W]) || (y < H - 1 && bg[i + W]);
            if (edge)
            {
                int m = minCh(i);
                int a = m <= 200 ? 255 : (int)(255 * (255 - m) / 55.0);
                px[i * 4 + 3] = (byte)Math.Max(60, Math.Min(255, a));
            }
        }
        Marshal.Copy(px, 0, data.Scan0, px.Length);
        bmp.UnlockBits(data);

        // trim
        int minX = W, minY = H, maxX = 0, maxY = 0;
        for (int i = 0; i < W * H; i++) if (px[i * 4 + 3] > 0) { int x = i % W, y = i / W; if (x < minX) minX = x; if (x > maxX) maxX = x; if (y < minY) minY = y; if (y > maxY) maxY = y; }
        minX = Math.Max(0, minX - pad); minY = Math.Max(0, minY - pad); maxX = Math.Min(W - 1, maxX + pad); maxY = Math.Min(H - 1, maxY + pad);
        var outBmp = bmp.Clone(new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1), PixelFormat.Format32bppArgb);
        bmp.Dispose();
        return outBmp;
    }

    public static void SavePngScaled(Bitmap src, string path, int width)
    {
        int h = (int)Math.Round(src.Height * (width / (double)src.Width));
        using (var b = Resize(src, width, h)) b.Save(path, ImageFormat.Png);
    }

    /// Square canvas with the source centred; optional solid background colour (null = transparent).
    public static Bitmap Square(Bitmap src, int size, double fill, Color? background)
    {
        var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.Clear(background ?? Color.Transparent);
            double s = Math.Min(size * fill / src.Width, size * fill / src.Height);
            int w = (int)Math.Round(src.Width * s), h = (int)Math.Round(src.Height * s);
            g.DrawImage(src, (size - w) / 2, (size - h) / 2, w, h);
        }
        return bmp;
    }

    /// Writes a multi-size .ico using PNG-compressed entries.
    public static void SaveIco(Bitmap src, string path, int[] sizes, double fill)
    {
        var pngs = new List<byte[]>();
        foreach (var s in sizes)
            using (var b = Square(src, s, fill, null))
            using (var ms = new MemoryStream()) { b.Save(ms, ImageFormat.Png); pngs.Add(ms.ToArray()); }
        using (var fs = new FileStream(path, FileMode.Create))
        using (var w = new BinaryWriter(fs))
        {
            w.Write((short)0); w.Write((short)1); w.Write((short)sizes.Length);
            int offset = 6 + 16 * sizes.Length;
            for (int i = 0; i < sizes.Length; i++)
            {
                w.Write((byte)(sizes[i] >= 256 ? 0 : sizes[i])); w.Write((byte)(sizes[i] >= 256 ? 0 : sizes[i]));
                w.Write((byte)0); w.Write((byte)0); w.Write((short)1); w.Write((short)32);
                w.Write(pngs[i].Length); w.Write(offset); offset += pngs[i].Length;
            }
            foreach (var p in pngs) w.Write(p);
        }
    }

    public static string SampleHex(string src, int x, int y)
    {
        using (var b = new Bitmap(src)) { var c = b.GetPixel(x, y); return string.Format("#{0:x2}{1:x2}{2:x2}", c.R, c.G, c.B); }
    }
}
