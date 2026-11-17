const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0a0f1c", /* black   */
  [1] = "#00bee3", /* red     */
  [2] = "#4bb3ff", /* green   */
  [3] = "#90a8eb", /* yellow  */
  [4] = "#88a6ff", /* blue    */
  [5] = "#d08de3", /* magenta */
  [6] = "#b097ff", /* cyan    */
  [7] = "#e2e8f6", /* white   */

  /* 8 bright colors */
  [8]  = "#9098ab",  /* black   */
  [9]  = "#3ad5fb",  /* red     */
  [10] = "#84c8ff", /* green   */
  [11] = "#a7bfff", /* yellow  */
  [12] = "#a7bfff", /* blue    */
  [13] = "#e7a3fb", /* magenta */
  [14] = "#c4b4ff", /* cyan    */
  [15] = "#e2e8f6", /* white   */

  /* special colors */
  [256] = "#0a0f1c", /* background */
  [257] = "#e2e8f6", /* foreground */
  [258] = "#e2e8f6",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
