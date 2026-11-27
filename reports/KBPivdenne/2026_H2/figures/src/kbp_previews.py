"""Two alternative 16:9 slide-layout previews from the exported 600 dpi PNG figures (layout only).

    python kbp_previews.py <figures_dir>   (Pillow; not with -I, which hides user site-packages)

Writes previews/KBP_kompozytsiia_A.png|.pdf and previews/KBP_kompozytsiia_B.png|.pdf (3840 x 2160 px).
Nothing is computed: the figures are scaled and placed; the slide title is a placeholder.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

W, H = 3840, 2160
FONT = 'C:/Windows/Fonts/arialbd.ttf'
FONT_R = 'C:/Windows/Fonts/arial.ttf'
TITLE = 'Вплив матеріальної архітектури на траєкторію і рушійну силу тріщини'
NOTE = 'Попередній перегляд компонування; не остаточний слайд. Розрахункові стани S0–S8.'


def fig(d, name):
    return Image.open(os.path.join(d, name + '.png')).convert('RGB')


def put(slide, im, box):
    """fit IM into BOX = (x, y, w, h), keep proportions, centre"""
    x, y, w, h = box
    s = min(w / im.width, h / im.height)
    r = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    slide.paste(r, (x + (w - r.width) // 2, y + (h - r.height) // 2))
    return r.size


def frame(title):
    s = Image.new('RGB', (W, H), 'white')
    dr = ImageDraw.Draw(s)
    dr.rectangle([0, 0, W, 190], fill=(0, 61, 113))
    dr.text((90, 95), title, font=ImageFont.truetype(FONT, 92), fill='white', anchor='lm')
    dr.text((90, H - 45), NOTE, font=ImageFont.truetype(FONT_R, 40), fill=(120, 120, 120), anchor='lm')
    return s, dr


def main(d):
    out = os.path.join(d, 'previews')
    os.makedirs(out, exist_ok=True)
    P1, P2a, P2b, P3 = (fig(d, n) for n in ['P1_materialni_konfihuratsii', 'P2a_traiektorii_spravzhnii_masshtab',
                                            'P2b_vidkhylennia_vid_H', 'P3_ekranuvannia_i_pidsylennia'])
    # A: four figures, 2 x 2 (overview slide)
    s, dr = frame(TITLE)
    top, gap, m = 230, 40, 60
    cw, ch = (W - 2 * m - gap) // 2, (H - top - 110 - gap) // 2
    put(s, P1, (m, top, cw, ch))
    put(s, P3, (m + cw + gap, top, cw, ch))
    put(s, P2a, (m, top + ch + gap, cw, ch))
    put(s, P2b, (m + cw + gap, top + ch + gap, cw, ch))
    dr.line([(W // 2, top + 20), (W // 2, H - 130)], fill=(225, 225, 225), width=4)
    dr.line([(m + 40, top + ch + gap // 2), (W - m - 40, top + ch + gap // 2)], fill=(225, 225, 225), width=4)
    s.save(os.path.join(out, 'KBP_kompozytsiia_A.png'), dpi=(300, 300))
    s.save(os.path.join(out, 'KBP_kompozytsiia_A.pdf'), resolution=300)
    # B: main result large (P3), configurations and true-scale paths beside it
    s, dr = frame(TITLE)
    top, m = 230, 60
    lw = 2050
    put(s, P3, (m, top + 60, lw, H - top - 280))
    rx, rw = m + lw + 50, W - (m + lw + 50) - m
    rh = (H - top - 110 - 40) // 2
    put(s, P1, (rx, top, rw, rh))
    put(s, P2a, (rx, top + rh + 40, rw, rh))
    dr.line([(rx - 25, top + 40), (rx - 25, H - 140)], fill=(225, 225, 225), width=4)
    s.save(os.path.join(out, 'KBP_kompozytsiia_B.png'), dpi=(300, 300))
    s.save(os.path.join(out, 'KBP_kompozytsiia_B.pdf'), resolution=300)
    print('previews written')


if __name__ == '__main__':
    main(sys.argv[1])
