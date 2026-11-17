static const char norm_fg[] = "#e2e8f6";
static const char norm_bg[] = "#0a0f1c";
static const char norm_border[] = "#9098ab";

static const char sel_fg[] = "#e2e8f6";
static const char sel_bg[] = "#4bb3ff";
static const char sel_border[] = "#e2e8f6";

static const char urg_fg[] = "#e2e8f6";
static const char urg_bg[] = "#00bee3";
static const char urg_border[] = "#00bee3";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
