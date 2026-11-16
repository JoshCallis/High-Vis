"""The Shots panel's look — the same palette as the Fusion windows and the Max Browser
(fusion_ui/theme.css): black fill, grey text that brightens for what's yours or chosen,
one blue accent, separators as faint white fills rather than lines.

Applied to the dock only (never to Max's main window).
"""
C = {
    "bg":       "#000000",
    "surface":  "#0b0b0b",
    "hover":    "rgba(255,255,255,10)",     # theme.css --panel-hover .04
    "focus":    "rgba(255,255,255,15)",     # --panel-focus .06
    "sel":      "rgba(255,255,255,23)",     # --panel-sel .09
    "sep":      "rgba(255,255,255,18)",     # --panel-sep .07
    "edge":     "#292929",
    "text":     "#9a9a9a",
    "dim":      "#6a6a6a",
    "faint":    "#3a3a3a",
    "bright":   "#d8d8d8",
    "accent":   "#5b97cf",
    "accent_bg": "rgba(91,151,207,46)",
    "warn":     "#d8c26a",
}
# Plain values for the card painter (QColor wants these, not CSS rgba strings).
RGBA = {
    "hover": (255, 255, 255, 10), "sel": (255, 255, 255, 23), "sep": (255, 255, 255, 18),
    "thumb_bg": (255, 255, 255, 8), "accent_bg": (91, 151, 207, 46),
}
FONT = "Segoe UI"

QSS = """
#callisRoot QWidget { color:%(text)s; font-family:"%(font)s"; font-size:12px; }
#callisRoot, #callisDetails, #callisRoot QAbstractScrollArea, #callisRoot QAbstractScrollArea > QWidget,
#callisRoot QStackedWidget, #callisRoot QSplitter, #callisRoot QTabWidget > QWidget { background:%(bg)s; }
#callisRoot QLabel[role="title"] { color:%(bright)s; font-size:14px; font-weight:600; }
#callisRoot QLabel[role="section"] { color:%(dim)s; font-size:10px; font-weight:600;
    letter-spacing:1px; padding-top:10px; }
#callisRoot QLabel[role="hint"] { color:%(dim)s; font-size:11px; }
#callisRoot QLabel[role="value"] { color:%(bright)s; }

#callisRoot QPushButton, #callisRoot QToolButton {
    background:%(hover)s; color:%(text)s; border:none; border-radius:4px; padding:4px 10px; }
#callisRoot QPushButton:hover, #callisRoot QToolButton:hover { background:%(sel)s; color:%(bright)s; }
#callisRoot QPushButton:pressed, #callisRoot QToolButton:pressed { background:%(focus)s; }
#callisRoot QPushButton:disabled { color:%(faint)s; background:transparent; }
#callisRoot QPushButton[role="primary"] { background:%(accent)s; color:#000; font-weight:600; padding:7px 14px; }
#callisRoot QPushButton[role="primary"]:hover { background:#78acdb; }
#callisRoot QPushButton[role="primary"]:disabled { background:%(sel)s; color:%(dim)s; }
#callisRoot QToolButton[role="lock"]:checked { color:%(accent)s; }
#callisRoot QToolButton::menu-indicator { image:none; width:0; }

#callisRoot QLineEdit, #callisRoot QSpinBox, #callisRoot QDoubleSpinBox, #callisRoot QComboBox, #callisRoot QPlainTextEdit {
    background:%(hover)s; color:%(bright)s; border:none; border-radius:4px; padding:3px 6px;
    selection-background-color:%(accent_bg)s; }
#callisRoot QLineEdit:focus, #callisRoot QSpinBox:focus, #callisRoot QDoubleSpinBox:focus, #callisRoot QComboBox:focus { background:%(focus)s; }
#callisRoot QSpinBox::up-button, #callisRoot QSpinBox::down-button,
#callisRoot QDoubleSpinBox::up-button, #callisRoot QDoubleSpinBox::down-button { width:0; border:none; }
#callisRoot QComboBox::drop-down { border:none; width:16px; }
#callisRoot QComboBox QAbstractItemView { background:%(surface)s; color:%(text)s; border:1px solid %(edge)s;
    selection-background-color:%(sel)s; selection-color:%(bright)s; outline:none; }
#callisRoot QPlainTextEdit { color:%(dim)s; font-family:Consolas; font-size:11px; }

#callisRoot QCheckBox { spacing:6px; }
#callisRoot QCheckBox::indicator { width:12px; height:12px; border-radius:3px; background:%(sel)s; }
#callisRoot QCheckBox::indicator:checked { background:%(accent)s; }
#callisRoot QCheckBox[role="pill"] { background:%(hover)s; border-radius:10px; padding:3px 9px; }
#callisRoot QCheckBox[role="pill"]:checked { background:%(accent_bg)s; color:%(bright)s; }
#callisRoot QCheckBox[role="pill"]::indicator { width:0; height:0; }

#callisRoot QListWidget, #callisRoot QTableWidget { background:transparent; border:none; outline:none; }
#callisRoot QListWidget[role="small"]::item { padding:2px 6px; border-radius:3px; }
#callisRoot QListWidget[role="small"]::item:hover { background:%(hover)s; }
#callisRoot QListWidget[role="small"]::item:selected { background:%(sel)s; color:%(bright)s; }
#callisRoot QTableWidget { gridline-color:transparent; }
#callisRoot QTableWidget::item { padding:2px 4px; border-bottom:1px solid %(sep)s; }
#callisRoot QHeaderView::section { background:transparent; color:%(dim)s; border:none; padding:4px; font-size:10px; }

#callisRoot QTabWidget::pane { border:none; }
#callisRoot QTabBar::tab { background:transparent; color:%(dim)s; padding:6px 12px; border:none;
    border-bottom:2px solid transparent; }
#callisRoot QTabBar::tab:selected { color:%(bright)s; border-bottom:2px solid %(accent)s; }
#callisRoot QTabBar::tab:hover:!selected { color:%(text)s; }

#callisRoot QFrame[role="banner"] { background:%(accent_bg)s; border-radius:6px; }
#callisRoot QFrame[role="banner"] QLabel { color:%(bright)s; }
#callisRoot QFrame[role="footer"] { background:%(surface)s; border-top:1px solid %(sep)s; }
#callisRoot QFrame[role="footer"] QAbstractScrollArea > QWidget { background:transparent; }
#callisRoot QSplitter::handle { background:%(sep)s; height:1px; }
#callisRoot QToolButton[role="more"] { padding:4px 6px; }

#callisRoot QScrollBar:vertical { background:transparent; width:8px; margin:0; }
#callisRoot QScrollBar::handle:vertical { background:%(sel)s; border-radius:4px; min-height:24px; }
#callisRoot QScrollBar::add-line, #callisRoot QScrollBar::sub-line { height:0; }
#callisRoot QScrollBar::add-page, #callisRoot QScrollBar::sub-page { background:transparent; }

QMenu#callisMenu { background:%(surface)s; color:%(text)s; border:1px solid %(edge)s; padding:4px; }
QMenu#callisMenu::item { padding:5px 18px; border-radius:3px; }
QMenu#callisMenu::item:selected { background:%(sel)s; color:%(bright)s; }
QMenu#callisMenu::separator { height:1px; background:%(sep)s; margin:4px 6px; }
""" % {**C, "font": FONT}
