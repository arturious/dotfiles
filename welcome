#!/usr/bin/env python3
"""Порт приветственного экрана Warp CLI (warpdotdev/warp, AGPL-3.0).

Источник: crates/warp_tui/src/zero_state_animation.rs и ui.rs (signed_out_welcome).
Алгоритмы, константы и раскладка перенесены один к одному; цвета взяты из темы
на скриншоте. Выход — любая клавиша.
"""
import fcntl
import math
import os
import select
import shutil
import sys
import termios
import time
import tty

TAU = math.tau

# --- константы из zero_state_animation.rs ----------------------------------
REPAINT_INTERVAL = 0.066
MIN_ANIMATION_COLS = 18
MIN_ANIMATION_ROWS = 7
MAX_LOGO_ROWS = 17
MIN_OBJECT_COLS = 5
MIN_OBJECT_ROWS = 5
BUILT_IN_LOGO_CELL_ASPECT_RATIO = 2.5
SURFACE_SAMPLES = 3
DEPTH_SAMPLES = 6
FACE_LINGER_STRENGTH = 0.2
CARDINAL_GLYPH_TANGENT_RATIO = 2.414213562373095
GHOST_STIPPLE_MODULUS = 19
SIDE_STITCH_MODULUS = 43
STARFIELD_REFERENCE_AREA = 52 * 20
STARFIELD_REFERENCE_COUNT = 36
STARFIELD_MIN_COUNT = 18
STARFIELD_CANDIDATE_BUDGET = 8192
STAR_TRAVEL_SECS = 7.0

# app/src/settings/tui_zero_state.rs
ROTATION_PERIOD_SECONDS = 5.0
EXTRUSION_DEPTH = 0.18

# ui.rs
AUTH_COPY_COLS = 48
AUTH_ANIMATION_COLS = 32

SVG_MIN_X, SVG_MAX_X = 35.0, 216.155
SVG_MIN_Y, SVG_MAX_Y = 25.5701, 170.489
UPPER_FACE = [
    (127.725, 25.5701), (196.111, 25.5701), (216.155, 46.2824),
    (216.155, 126.695), (196.111, 147.407), (98.2486, 147.407),
]
LOWER_FACE = [
    (109.963, 48.652), (54.8733, 48.652), (35.0, 69.3643), (35.0, 149.777),
    (54.8733, 170.489), (122.676, 170.489), (125.395, 159.154), (83.4561, 159.154),
]

# --- стили (цвета со скриншота) --------------------------------------------
ESC = "\x1b["
RESET = ESC + "0m"


def rgb(r, g, b, *mods):
    return ESC + ";".join(list(mods) + ["38;2;%d;%d;%d" % (r, g, b)]) + "m"


PRIMARY = rgb(236, 236, 236)
MUTED = rgb(150, 150, 150)
DIM = rgb(150, 150, 150, "2")
BRAND_PRIMARY_BOLD = rgb(204, 170, 255, "1")
BRAND_ACCENT = rgb(236, 236, 236)
BRAND_ACCENT_BOLD = rgb(232, 255, 214, "1")
LINK_UNDERLINED = rgb(236, 236, 236, "4")
LINK = rgb(236, 236, 236)
ACCENT = rgb(200, 186, 255)  # front: cyan темы, на скриншоте — лавандовый

STYLE_FRONT, STYLE_BACK, STYLE_SIDE = ACCENT, PRIMARY, DIM
STYLE_STARS = MUTED

# --- текст (ui.rs: signed_out_welcome) -------------------------------------
CONTENT = [
    [("Welcome back, ARTHUR :3", BRAND_PRIMARY_BOLD)],
]
CONTENT_PADDING_LEFT = 3


# --- математика ------------------------------------------------------------
def rround(x):
    """Rust f64::round — половина от нуля."""
    return int(math.copysign(math.floor(abs(x) + 0.5), x))


def as_usize(x):
    """Rust `as usize` насыщает отрицательные значения до нуля."""
    return max(0, rround(x))


M64 = (1 << 64) - 1


def unit_random(seed):
    value = (seed + 0x9E3779B97F4A7C15) & M64
    value = ((value ^ (value >> 30)) * 0xBF58476D1CE4E5B9) & M64
    value = ((value ^ (value >> 27)) * 0x94D049BB133111EB) & M64
    return ((value ^ (value >> 31)) >> 11) / float(1 << 53)


def point_in_polygon(x, y, polygon):
    inside = False
    previous = len(polygon) - 1
    for current in range(len(polygon)):
        cx, cy = polygon[current]
        px, py = polygon[previous]
        if (cy > y) != (py > y) and x < (px - cx) * (y - cy) / (py - cy) + cx:
            inside = not inside
        previous = current
    return inside


def warp_logo_contains(x, y):
    svg_x = SVG_MIN_X + (x + 1.0) * 0.5 * (SVG_MAX_X - SVG_MIN_X)
    svg_y = SVG_MIN_Y + (y + 1.0) * 0.5 * (SVG_MAX_Y - SVG_MIN_Y)
    return point_in_polygon(svg_x, svg_y, UPPER_FACE) or point_in_polygon(svg_x, svg_y, LOWER_FACE)


# --- свой рисунок ----------------------------------------------------------
# Рисунок крутится как есть, символ в символ, в масштабе 1:1. Как у логотипа
# Warp, у него две грани (передняя — акцентным цветом, задняя — тусклая) на
# расстоянии EXTRUSION_DEPTH, а по краям строк — «стежки» из точек.
# Нет файла — крутится логотип Warp.
ART_RIGHT_MARGIN = 2  # отступ рисунка от правого края, в колонках
SHAPE_FILE = os.path.expanduser("~/dotfiles/ascii/logo.txt")
try:
    with open(SHAPE_FILE) as f:
        SHAPE = f.read()
except OSError:
    SHAPE = None

# Символы, которые при взгляде на обратную сторону меняются на зеркальные.
MIRROR = str.maketrans("/\\()<>[]{}`'", "\\/)(><][}{'`")


class ArtProjector:
    def __init__(self, source):
        rows = source.replace("\r\n", "\n").expandtabs().split("\n")
        cells = [(x, y, ch) for y, row in enumerate(rows)
                 for x, ch in enumerate(row) if ch != " "]
        min_x = min(x for x, _, _ in cells)
        max_x = max(x for x, _, _ in cells)
        min_y = min(y for _, y, _ in cells)
        max_y = max(y for _, y, _ in cells)
        self.width = max_x - min_x + 1
        self.height = max_y - min_y + 1
        cx = (self.width - 1) / 2.0
        self.cells = [(x - min_x - cx, y - min_y, ch) for x, y, ch in cells]
        # края каждой строки — там рисуется боковая грань
        edges = {}
        for x, y, _ in self.cells:
            lo, hi = edges.get(y, (x, x))
            edges[y] = (min(lo, x), max(hi, x))
        self.edges = [(x, y) for y, (lo, hi) in edges.items() for x in {lo, hi}]
        self.depth = EXTRUSION_DEPTH * cx
        # панель: рисунок плюс место под толщину при повороте
        self.panel_width = self.width + 2 * int(math.ceil(self.depth)) + 2

    def project(self, width, height, angle):
        angle = face_linger_angle(angle)
        sin, cos = math.sin(angle), math.cos(angle)
        center_x = (width - 1.0) / 2.0
        top = (height - self.height) // 2
        mirrored = cos < 0
        zbuf = {}

        def put(mx, my, mz, cell):
            px = rround(center_x + mx * cos + mz * sin)
            py = top + my
            if not (0 <= px < width and 0 <= py < height):
                return
            depth = -mx * sin + mz * cos
            cur = zbuf.get((px, py))
            if cur is None or depth > cur[0]:
                zbuf[(px, py)] = (depth, cell)

        for mx, my, ch in self.cells:
            glyph = ch.translate(MIRROR) if mirrored else ch
            put(mx, my, self.depth, (glyph, STYLE_FRONT))
            put(mx, my, -self.depth, (glyph, STYLE_SIDE))
        for mx, my in self.edges:
            for i in range(1, DEPTH_SAMPLES):
                mz = -self.depth + 2.0 * self.depth * i / DEPTH_SAMPLES
                put(mx, my, mz, (".", STYLE_SIDE))
        return {k: v[1] for k, v in zbuf.items()}


def sample_coordinate(index, count):
    return ((index + 0.5) / count) * 2.0 - 1.0


def glyph_for_tangent(tx, ty):
    if tx == 0.0 and ty == 0.0:
        return None
    if abs(tx) > abs(ty) * CARDINAL_GLYPH_TANGENT_RATIO:
        return "-"
    if abs(ty) > abs(tx) * CARDINAL_GLYPH_TANGENT_RATIO:
        return "|"
    if math.copysign(1, tx) == math.copysign(1, ty):
        return "\\"
    return "/"


def face_linger_angle(phase):
    return phase - FACE_LINGER_STRENGTH * math.sin(2.0 * phase) / 2.0


def fitted_logo_size(width, height, aspect):
    if width < MIN_ANIMATION_COLS or height < MIN_ANIMATION_ROWS:
        return None
    available_cols = max(0, width - 2)
    available_rows = max(0, height - 2)
    max_rows = min(available_rows, MAX_LOGO_ROWS)
    natural_cols = rround(max_rows * aspect)
    if natural_cols <= available_cols:
        return max(natural_cols, MIN_OBJECT_COLS), max_rows
    cols = available_cols
    fitted_rows = rround(cols / aspect)
    if fitted_rows < MIN_OBJECT_ROWS:
        return cols, MIN_OBJECT_ROWS
    rows = min(fitted_rows, max_rows)
    cols = max(min(rround(rows * aspect), cols), MIN_OBJECT_COLS)
    return cols, rows


# --- логотип ---------------------------------------------------------------
class LogoProjector:
    def __init__(self):
        self.key = None
        self.samples = []

    def geometry(self, logo_cols, logo_rows):
        if self.key == (logo_cols, logo_rows):
            return self.samples
        source_cols = logo_cols * SURFACE_SAMPLES
        source_rows = logo_rows * SURFACE_SAMPLES
        dx = 2.0 / source_cols
        dy = 2.0 / source_rows
        c = warp_logo_contains
        samples = []
        for sy in range(source_rows):
            my = sample_coordinate(sy, source_rows)
            for sx in range(source_cols):
                mx = sample_coordinate(sx, source_cols)
                if not c(mx, my):
                    continue
                left, right = c(mx - dx, my), c(mx + dx, my)
                above, below = c(mx, my - dy), c(mx, my + dy)
                samples.append((
                    mx, my,
                    float(left) - float(right),
                    float(above) - float(below),
                    (sx * 13 + sy * 7) % SIDE_STITCH_MODULUS == 0,
                ))
        self.key = (logo_cols, logo_rows)
        self.samples = samples
        return samples

    def project(self, width, height, angle):
        """Возвращает {(x, y): (glyph, style)} в координатах области анимации."""
        aspect = BUILT_IN_LOGO_CELL_ASPECT_RATIO
        fitted = fitted_logo_size(width, height, aspect)
        if fitted is None:
            return {}
        logo_cols, logo_rows = fitted
        samples = self.geometry(logo_cols, logo_rows)

        angle = face_linger_angle(angle)
        sin, cos = math.sin(angle), math.cos(angle)
        center_x = (width - 1.0) / 2.0
        center_y = (height - 1.0) / 2.0
        scale_x = (logo_cols - 1.0) / 2.0
        scale_y = (logo_rows - 1.0) / 2.0
        zbuf = {}

        for mx, my, nx, ny, stitch in samples:
            outline = glyph_for_tangent(-ny * cos * aspect, nx)
            for depth_index in range(DEPTH_SAMPLES + 1):
                is_face = depth_index == 0 or depth_index == DEPTH_SAMPLES
                if not is_face and (outline is None or not stitch):
                    continue
                mz = -EXTRUSION_DEPTH + 2.0 * EXTRUSION_DEPTH * depth_index / DEPTH_SAMPLES
                rx = mx * cos + mz * sin
                depth = -mx * sin + mz * cos
                px = rround(center_x + rx * scale_x)
                py = rround(center_y + my * scale_y)
                if px < 0 or py < 0 or px >= width or py >= height:
                    continue
                if is_face and outline is None and (px * 17 + py * 31) % GHOST_STIPPLE_MODULUS != 0:
                    continue
                if not is_face:
                    cell = (".", STYLE_SIDE)
                elif outline is not None:
                    cell = (outline, STYLE_FRONT if depth_index == DEPTH_SAMPLES else STYLE_BACK)
                else:
                    cell = (".", STYLE_SIDE)  # ghost
                cur = zbuf.get((px, py))
                if cur is None or depth > cur[0]:
                    zbuf[(px, py)] = (depth, cell)
        return {k: v[1] for k, v in zbuf.items()}


# --- звёзды ----------------------------------------------------------------
def star_count_for_size(width, height):
    scaled = width * height * STARFIELD_REFERENCE_COUNT // STARFIELD_REFERENCE_AREA
    return min(max(scaled, STARFIELD_MIN_COUNT), STARFIELD_CANDIDATE_BUDGET)


def starfield_emitter_x(width, leading_reserved_cols, logo_panel_cols):
    available = max(0, width - leading_reserved_cols)
    if available < MIN_ANIMATION_COLS:
        return (width - 1.0) / 2.0
    panel = min(available, logo_panel_cols)
    spacer = -(-(available - panel) // 2)
    return float(leading_reserved_cols + spacer) + (panel - 1.0) / 2.0


def for_each_star(width, height, elapsed, center_x):
    center_y = (height - 1.0) / 2.0
    for index in range(star_count_for_size(width, height)):
        seed = index ^ 0xA5A56C8E9CF5703B
        angle = unit_random(seed) * TAU
        phase = unit_random(seed ^ 0x6E624EB7F3A192D1)
        speed = 0.75 + unit_random(seed ^ 0xD1B54A32D192ED03) * 0.5
        progress = math.modf(phase + elapsed / STAR_TRAVEL_SECS * speed)[0]
        dxn, dyn = math.cos(angle), math.sin(angle)
        radius_x = center_x / max(abs(dxn), 0.001)
        radius_y = center_y * 2.0 / max(abs(dyn), 0.001)
        max_radius = min(radius_x, radius_y)
        radius = 1.0 + progress ** 1.4 * max(max_radius - 1.0, 0.0)
        x = as_usize(center_x + dxn * radius)
        y = as_usize(center_y + dyn * radius / 2.0)
        if x >= width or y >= height:
            continue
        glyph = "." if progress < 0.7 else ("+" if progress < 0.9 else "*")
        yield x, y, glyph


# --- раскладка (ui.rs: auth_layout) ----------------------------------------
def render(projector, elapsed):
    width, height = shutil.get_terminal_size((80, 24))
    grid = [[(" ", None)] * width for _ in range(height)]

    # слой 2 считается первым: от его положения зависит центр звёзд
    if hasattr(projector, "panel_width"):
        # свой рисунок прижат к правому краю экрана
        anim_w = min(width, projector.panel_width)
        anim_x = max(0, width - anim_w - ART_RIGHT_MARGIN)
    else:
        available = max(0, width - AUTH_COPY_COLS)
        anim_w = min(available, AUTH_ANIMATION_COLS)
        anim_x = AUTH_COPY_COLS + (available - anim_w) // 2

    # слой 1: звёзды на весь экран, разлетаются из центра фигуры
    emitter = anim_x + (anim_w - 1.0) / 2.0
    for x, y, g in for_each_star(width, height, elapsed, emitter):
        grid[y][x] = (g, STYLE_STARS)

    # слой 2: фигура
    if anim_w >= MIN_ANIMATION_COLS and height >= MIN_ANIMATION_ROWS:
        idle_velocity = TAU / ROTATION_PERIOD_SECONDS
        angle = (elapsed * idle_velocity) % TAU
        for (x, y), cell in projector.project(anim_w, height, angle).items():
            grid[y][anim_x + x] = cell

    # слой 3: текст, по центру по вертикали, с очищенным фоном. Рядом со
    # своим рисунком — ещё и по центру свободного места слева от него.
    text_w = max(sum(len(t) for t, _ in spans) for spans in CONTENT)
    left = CONTENT_PADDING_LEFT
    if hasattr(projector, "panel_width"):
        art_left = anim_x + (anim_w - projector.width) // 2
        left = max(CONTENT_PADDING_LEFT, (art_left - text_w) // 2)
    top = max(0, (height - len(CONTENT)) // 2)
    for row, spans in enumerate(CONTENT):
        y = top + row
        if y >= height:
            break
        line_w = sum(len(t) for t, _ in spans)
        for x in range(max(0, left - 1), min(width, left + line_w + 1)):
            grid[y][x] = (" ", None)
        x = left
        for text, style in spans:
            for ch in text:
                if x < width:
                    grid[y][x] = (ch, style)
                x += 1

    out = [ESC + "H"]
    last = None
    for r, row in enumerate(grid):
        for ch, style in row:
            if style != last:
                out.append(RESET)
                if style:
                    out.append(style)
                last = style
            out.append(ch)
        if r < height - 1:
            out.append("\r\n")
    out.append(RESET)
    sys.stdout.write("".join(out))
    sys.stdout.flush()


def main():
    limit = None
    if len(sys.argv) > 2 and sys.argv[1] == "--once":
        limit = float(sys.argv[2])
    if not sys.stdout.isatty() or not sys.stdin.isatty():
        return

    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    projector = ArtProjector(SHAPE) if SHAPE else LogoProjector()
    pressed = b""
    # Заголовок панели (#T во вкладках tmux) — «*», пока открыт экран;
    # после выхода fish сам вернёт свой заголовок через fish_title.
    sys.stdout.write("\x1b]2;*\x1b\\")
    sys.stdout.write(ESC + "?1049h" + ESC + "?25l" + ESC + "2J")
    try:
        tty.setcbreak(fd)
        start = time.monotonic()
        while True:
            elapsed = time.monotonic() - start
            if limit is not None and elapsed >= limit:
                break
            render(projector, elapsed)
            ready, _, _ = select.select([sys.stdin], [], [], REPAINT_INTERVAL)
            if ready:
                pressed = os.read(fd, 64)
                break
    except KeyboardInterrupt:
        pass
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        sys.stdout.write(RESET + ESC + "?25h" + ESC + "?1049l")
        sys.stdout.flush()
        # Нажатая клавиша не теряется: возвращаем её во ввод терминала,
        # и она попадает в командную строку shell.
        for byte in pressed:
            try:
                fcntl.ioctl(fd, termios.TIOCSTI, bytes([byte]))
            except OSError:
                break


if __name__ == "__main__":
    main()
