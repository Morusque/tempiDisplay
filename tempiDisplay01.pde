
String outputFilename = "tempiSet01.txt";
float[] tempi = {-1};  // Enter fixed tempo or -1 to tap live
String[] trackNames = {"Track 1"};

float minTempo, maxTempo;
float minSuggestion = 50;
float maxSuggestion = 200;
float leftMargin = 40;
float labelWidth = 260;
float chartRightMargin = 60;
float hoverRadius = 10;
int hoveredIndex = -1;
int selectedTrack = 0;
String editingMode = ""; // "tempo", "title", "divide", "multiply", "min", "max"
int editTrack = -1;
String tempoInput = "";
float[] divideFactors;
float[] multiplyFactors;

float topGuideY;
float rowHeight = 36;
color[] trackColors;
float[] suggestionTempi;
float[] suggestionTempiBaseOnly;
ArrayList<Long> tapTimes;
String tapMessage = "Click TAP repeatedly for tempo";
boolean showSaveMessage = false;
int saveMessageTimer = 0;

void setup() {
  size(1400, 1000);
  textAlign(CENTER, CENTER);
  textSize(14);

  topGuideY = 220;
  tapTimes = new ArrayList<Long>();

  initTrackColors();
  initializeTrackFactors();
  recomputeTempoBounds();
  suggestionTempi = computeSuggestions(5);
  suggestionTempiBaseOnly = computeSuggestionsBaseOnly(5);
}

void initializeTrackFactors() {
  divideFactors = new float[tempi.length];
  multiplyFactors = new float[tempi.length];
  for (int i = 0; i < tempi.length; i++) {
    divideFactors[i] = 2;
    multiplyFactors[i] = 2;
  }
}

void draw() {
  background(255);
  drawHeader();
  drawButtons();
  drawTimelineGuide();
  drawTrackRows();
  showHoverTempo(mouseX, mouseY);
  drawSuggestions();
  drawStatus();
}

void initTrackColors() {
  trackColors = new color[tempi.length];
  color[] palette = {
    color(220, 70, 70),
    color(60, 140, 235),
    color(40, 170, 100),
    color(180, 120, 40),
    color(150, 80, 190),
    color(30, 170, 170),
    color(210, 90, 180),
    color(100, 180, 120)
  };

  for (int i = 0; i < tempi.length; i++) {
    trackColors[i] = palette[i % palette.length];
  }
}

void drawHeader() {
  fill(0);
  textAlign(LEFT, CENTER);
  textSize(16);
  text("Tempo tap editor — selected: " + trackNames[selectedTrack], leftMargin, 24);
  textSize(12);
  text("Enter fixed tempo in the code, or use TAP to record a tempo for the selected track.", leftMargin, 44);
  text("Save writes " + outputFilename + " to the sketch folder.", leftMargin, 60);
  textAlign(CENTER, CENTER);
  textSize(14);
}

void drawButtons() {
  float buttonY = 110;
  float buttonW = 88;
  float buttonH = 32;
  drawButton("Prev Track", leftMargin, buttonY, buttonW, buttonH, false);
  drawButton("Next Track", leftMargin + buttonW + 10, buttonY, buttonW, buttonH, false);
  drawButton("Tap", leftMargin + 2 * (buttonW + 10), buttonY, buttonW, buttonH, false);
  drawButton("Edit", leftMargin + 3 * (buttonW + 10), buttonY, buttonW, buttonH, editingMode.equals("tempo"));
  drawButton("Title", leftMargin + 4 * (buttonW + 10), buttonY, buttonW, buttonH, editingMode.equals("title"));
  drawButton("Add Track", leftMargin + 5 * (buttonW + 10), buttonY, buttonW, buttonH, false);
  drawButton("Remove Track", leftMargin + 6 * (buttonW + 10), buttonY, buttonW, buttonH, false);
  drawButton("Zoom In", leftMargin + 7 * (buttonW + 10), buttonY, buttonW, buttonH, false);
  drawButton("Zoom Out", leftMargin + 8 * (buttonW + 10), buttonY, buttonW, buttonH, false);
  drawButton("Save", leftMargin + 9 * (buttonW + 10), buttonY, buttonW, buttonH, false);
  drawButton("Load", leftMargin + 10 * (buttonW + 10), buttonY, buttonW, buttonH, false);
  drawRangeField("Min", leftMargin + 11 * (buttonW + 10), buttonY, 80, buttonH, minSuggestion, editingMode.equals("min"));
  drawRangeField("Max", leftMargin + 11 * (buttonW + 10) + 90, buttonY, 80, buttonH, maxSuggestion, editingMode.equals("max"));
}

void drawButton(String label, float x, float y, float w, float h, boolean active) {
  rectMode(CORNER);
  stroke(0);
  strokeWeight(1);
  fill(active ? 200 : 240);
  rect(x, y, w, h, 5);
  fill(0);
  noStroke();
  textAlign(CENTER, CENTER);
  textSize(12);
  text(label, x + w / 2, y + h / 2);
  textSize(14);
}

void drawRangeField(String label, float x, float y, float w, float h, float value, boolean active) {
  rectMode(CORNER);
  stroke(0);
  strokeWeight(1);
  fill(active ? color(230, 240, 255) : 245);
  rect(x, y, w, h, 5);
  fill(0);
  noStroke();
  textAlign(CENTER, CENTER);
  textSize(11);
  text(label + ": " + int(value), x + w / 2, y + h / 2);
  textSize(14);
}

void drawTimelineGuide() {
  float y = topGuideY;
  rectMode(CORNER);
  stroke(215);
  strokeWeight(1);
  line(chartLeft(), y, chartRight(), y);

  // Subtle vertical bars at various BPM
  float[] marks = {20, 25, 30, 40, 50, 60, 70, 80, 90, 100, 120, 140, 150, 160, 180, 200, 240, 280, 320, 400, 480};
  for (float mark : marks) {
    if (mark >= minTempo && mark <= maxTempo) {
      float x = tempoToX(mark);
      stroke(180, 100);
      strokeWeight(1);
      line(x, topGuideY, x, height - chartRightMargin);
      noStroke();
      fill(120);
      textSize(10);
      textAlign(CENTER, BOTTOM);
      text(str((int)mark), x, topGuideY - 12);
      textAlign(CENTER, CENTER);
    }
  }
}

void drawTrackRows() {
  ensureTrackArrays();
  drawSuggestionRow(topGuideY + 60);
  for (int i = 0; i < tempi.length; i++) {
    float y = topGuideY + 60 + (i + 1) * rowHeight;
    drawTrackRow(i, y);
  }
}

void ensureTrackArrays() {
  if (trackColors == null || trackColors.length != tempi.length) {
    initTrackColors();
  }
  if (divideFactors == null || divideFactors.length != tempi.length || multiplyFactors == null || multiplyFactors.length != tempi.length) {
    float[] newDivide = new float[tempi.length];
    float[] newMultiply = new float[tempi.length];
    for (int i = 0; i < tempi.length; i++) {
      newDivide[i] = divideFactors != null && i < divideFactors.length ? divideFactors[i] : 2;
      newMultiply[i] = multiplyFactors != null && i < multiplyFactors.length ? multiplyFactors[i] : 2;
    }
    divideFactors = newDivide;
    multiplyFactors = newMultiply;
  }
}

void drawSuggestionRow(float y) {
  stroke(200);
  strokeWeight(1);
  line(chartLeft(), y, chartRight(), y);

  noStroke();
  fill(80);
  textAlign(LEFT, CENTER);
  textSize(12);
  text("Suggestions (base only)", leftMargin + 10, y);

  float[] sizes = {22, 18, 14, 10, 8};
  for (int i = 0; i < suggestionTempiBaseOnly.length; i++) {
    float t = suggestionTempiBaseOnly[i];
    if (t <= 0 || t < minTempo || t > maxTempo) continue;
    float x = tempoToX(t);
    float size = sizes[min(i, sizes.length - 1)];

    stroke(0);
    strokeWeight(1);
    fill(200);
    ellipse(x, y, size, size);

    noStroke();
    fill(0);
    textSize(10);
    text(formatTempo(t), x, y - size - 4);
  }
  textSize(14);
}

void drawTrackRow(int index, float y) {
  boolean selected = index == selectedTrack;
  float lineY = y;
  float tempo = tempi[index];
  color c = trackColors[index];

  float fieldWidth = 60;
  float fieldHeight = 22;
  float divideX = leftMargin + labelWidth - 140;
  float multiplyX = leftMargin + labelWidth - 70;

  if (selected) {
    noStroke();
    fill(240, 240, 255);
    rect(chartLeft() - 10, lineY - 18, chartRight() - chartLeft() + 20, 36, 6);
  }

  stroke(200);
  strokeWeight(1);
  line(chartLeft(), lineY, chartRight(), lineY);

  if (tempo > 0) {
    float divFactor = max(divideFactors[index], 1);
    float t = tempo / divFactor;
    while (t >= minTempo) {
      float x = tempoToX(t);
      stroke(c, 160);
      strokeWeight(1);
      fill(c, 120);
      ellipse(x, lineY, 8, 8);
      t /= 2;
    }

    float mulFactor = max(multiplyFactors[index], 1);
    t = tempo * mulFactor;
    while (t <= maxTempo) {
      float x = tempoToX(t);
      stroke(c, 160);
      strokeWeight(1);
      fill(c, 120);
      ellipse(x, lineY, 8, 8);
      t *= 2;
    }

    float x = tempoToX(tempo);
    stroke(255);
    strokeWeight(1.5);
    fill(c);
    ellipse(x, lineY, selected ? 18 : 14, selected ? 18 : 14);

    noStroke();
    fill(0);
    textAlign(LEFT, CENTER);
    textSize(12);
    text(trackNames[index] + " — " + formatTempo(tempo) + " bpm", leftMargin + 10, lineY);
  } else {
    noStroke();
    fill(120);
    textAlign(LEFT, CENTER);
    textSize(12);
    text(trackNames[index] + " — unset (-1)", leftMargin + 10, lineY);
    stroke(c);
    noFill();
    ellipse(chartLeft(), lineY, 12, 12);
  }

  drawParamField(divideX, lineY, fieldWidth, fieldHeight, "÷", divideFactors[index], index, "divide");
  drawParamField(multiplyX, lineY, fieldWidth, fieldHeight, "×", multiplyFactors[index], index, "multiply");

  if (selected) {
    stroke(c);
    strokeWeight(2);
    line(chartLeft(), lineY - 18, chartLeft(), lineY + 18);
  }
}

void drawParamField(float x, float y, float w, float h, String label, float value, int trackIndex, String mode) {
  boolean active = editTrack == trackIndex && editingMode.equals(mode);
  stroke(150);
  strokeWeight(1);
  fill(active ? color(230, 240, 255) : 245);
  rect(x, y - h / 2, w, h, 4);
  noStroke();
  fill(0);
  textAlign(CENTER, CENTER);
  textSize(11);
  text(label + nf(value, 0, 0), x + w / 2, y);
}
void drawSuggestions() {
  if (suggestionTempi == null) return;

  float y = topGuideY + 20;
  stroke(200);
  strokeWeight(1);
  line(chartLeft(), y, chartRight(), y);

  noStroke();
  fill(80);
  textAlign(LEFT, CENTER);
  textSize(12);
  text("Suggestions (with dividers)", leftMargin + 10, y);

  float[] sizes = {22, 18, 14, 10, 8};
  for (int i = 0; i < suggestionTempi.length; i++) {
    float t = suggestionTempi[i];
    if (t <= 0 || t < minTempo || t > maxTempo) continue;
    float x = tempoToX(t);
    float size = sizes[min(i, sizes.length - 1)];

    stroke(0);
    strokeWeight(1);
    fill(200);
    ellipse(x, y, size, size);

    noStroke();
    fill(0);
    textAlign(CENTER, BOTTOM);
    textSize(10);
    text(formatTempo(t), x, y - size - 4);
    textAlign(CENTER, CENTER);
  }
  textSize(14);
}

void drawStatus() {
  fill(0);
  textAlign(LEFT, CENTER);
  textSize(12);
  text("Tap info: " + tapMessage, leftMargin, height - 60);
  if (!editingMode.equals("")) {
    String label = editingMode.equals("tempo") ? "Editing tempo" :
      editingMode.equals("title") ? "Editing title" :
      editingMode.equals("min") || editingMode.equals("max") ? "Editing " + editingMode + " boundary" :
      "Editing " + editingMode + " factor";
    text(label + " for " + trackNames[editTrack] + ": " + tempoInput + "_", leftMargin, height - 40);
  }
  if (showSaveMessage) {
    text("Saved to " + outputFilename, width - chartRightMargin - 180, height - 60);
    if (millis() - saveMessageTimer > 1800) {
      showSaveMessage = false;
    }
  }
  textAlign(CENTER, CENTER);
  textSize(14);
}

void showHoverTempo(float x, float y) {
  if (x < chartLeft() || x > chartRight()) return;
  float hoveredY = getHoveredRowY(y);
  if (hoveredY < 0) return;

  float tempo = xToTempo(constrain(x, chartLeft(), chartRight()));
  float labelY = hoveredY - 24;
  fill(255, 255, 200);
  stroke(0);
  rectMode(CENTER);
  rect(x, labelY, 104, 28, 5);
  rectMode(CORNER);
  fill(0);
  noStroke();
  textAlign(CENTER, CENTER);
  text(formatTempo(tempo) + " bpm", x, labelY);
}

float getHoveredRowY(float y) {
  float suggestionsY = topGuideY + 20;
  if (abs(y - suggestionsY) <= rowHeight / 2) return suggestionsY;
  float suggestionsBaseY = topGuideY + 60;
  if (abs(y - suggestionsBaseY) <= rowHeight / 2) return suggestionsBaseY;
  for (int i = 0; i < tempi.length; i++) {
    float rowY = topGuideY + 60 + (i + 1) * rowHeight;
    if (abs(y - rowY) <= rowHeight / 2) return rowY;
  }
  return -1;
}

void mousePressed() {
  float buttonY = 110;
  float buttonW = 88;
  float buttonH = 32;

  if (hitButton(mouseX, mouseY, leftMargin, buttonY, buttonW, buttonH)) {
    selectPreviousTrack();
    return;
  }
  if (hitButton(mouseX, mouseY, leftMargin + buttonW + 10, buttonY, buttonW, buttonH)) {
    selectNextTrack();
    return;
  }
  if (hitButton(mouseX, mouseY, leftMargin + 2 * (buttonW + 10), buttonY, buttonW, buttonH)) {
    handleTap();
    return;
  }
  if (hitButton(mouseX, mouseY, leftMargin + 3 * (buttonW + 10), buttonY, buttonW, buttonH)) {
    startTempoEdit();
    return;
  }
  if (hitButton(mouseX, mouseY, leftMargin + 4 * (buttonW + 10), buttonY, buttonW, buttonH)) {
    startTitleEdit();
    return;
  }
  if (hitButton(mouseX, mouseY, leftMargin + 5 * (buttonW + 10), buttonY, buttonW, buttonH)) {
    addTrack();
    return;
  }
  if (hitButton(mouseX, mouseY, leftMargin + 6 * (buttonW + 10), buttonY, buttonW, buttonH)) {
    removeTrack();
    return;
  }
  if (hitButton(mouseX, mouseY, leftMargin + 7 * (buttonW + 10), buttonY, buttonW, buttonH)) {
    zoomIn();
    return;
  }
  if (hitButton(mouseX, mouseY, leftMargin + 8 * (buttonW + 10), buttonY, buttonW, buttonH)) {
    zoomOut();
    return;
  }
  if (hitButton(mouseX, mouseY, leftMargin + 9 * (buttonW + 10), buttonY, buttonW, buttonH)) {
    selectOutput("Choose a tempo save file:", "fileSelected");
    return;
  }
  if (hitButton(mouseX, mouseY, leftMargin + 10 * (buttonW + 10), buttonY, buttonW, buttonH)) {
    selectInput("Choose a tempo load file:", "loadFileSelected");
    return;
  }

  float minX = leftMargin + 11 * (buttonW + 10);
  float maxX = minX + 90;
  if (mouseY >= buttonY && mouseY <= buttonY + buttonH) {
    if (mouseX >= minX && mouseX <= minX + 80) {
      startParamEdit("min", selectedTrack);
      return;
    }
    if (mouseX >= maxX && mouseX <= maxX + 80) {
      startParamEdit("max", selectedTrack);
      return;
    }
  }

  // Select track by clicking its row
  float fieldWidth = 60;
  float fieldHeight = 22;
  float divideX = leftMargin + labelWidth - 140;
  float multiplyX = leftMargin + labelWidth - 70;

  for (int i = 0; i < tempi.length; i++) {
    float y = topGuideY + 60 + (i + 1) * rowHeight;
    if (abs(mouseY - y) < rowHeight / 2) {
      if (mouseX >= divideX && mouseX <= divideX + fieldWidth) {
        startParamEdit("divide", i);
        return;
      }
      if (mouseX >= multiplyX && mouseX <= multiplyX + fieldWidth) {
        startParamEdit("multiply", i);
        return;
      }
      selectedTrack = i;
      editingMode = "";
      break;
    }
  }
}

void addTrack() {
  float[] newTempi = new float[tempi.length + 1];
  String[] newTrackNames = new String[trackNames.length + 1];
  float[] newDivide = new float[divideFactors.length + 1];
  float[] newMultiply = new float[multiplyFactors.length + 1];

  arrayCopy(tempi, newTempi);
  arrayCopy(trackNames, newTrackNames);
  arrayCopy(divideFactors, newDivide);
  arrayCopy(multiplyFactors, newMultiply);

  newTempi[tempi.length] = -1;
  newTrackNames[trackNames.length] = "Track " + (trackNames.length + 1);
  newDivide[divideFactors.length] = 2;
  newMultiply[multiplyFactors.length] = 2;

  tempi = newTempi;
  trackNames = newTrackNames;
  divideFactors = newDivide;
  multiplyFactors = newMultiply;

  initTrackColors();
  recomputeTempoBounds();
  suggestionTempi = computeSuggestions(5);
  suggestionTempiBaseOnly = computeSuggestionsBaseOnly(5);
  selectedTrack = tempi.length - 1;
  tapMessage = "Added new track: " + trackNames[selectedTrack];
}

void removeTrack() {
  if (tempi.length <= 1) {
    tapMessage = "Cannot remove the last track.";
    return;
  }
  float[] newTempi = new float[tempi.length - 1];
  String[] newTrackNames = new String[trackNames.length - 1];
  float[] newDivide = new float[divideFactors.length - 1];
  float[] newMultiply = new float[multiplyFactors.length - 1];
  int idx = 0;
  for (int i = 0; i < tempi.length; i++) {
    if (i != selectedTrack) {
      newTempi[idx] = tempi[i];
      newTrackNames[idx] = trackNames[i];
      newDivide[idx] = divideFactors[i];
      newMultiply[idx] = multiplyFactors[i];
      idx++;
    }
  }
  tempi = newTempi;
  trackNames = newTrackNames;
  divideFactors = newDivide;
  multiplyFactors = newMultiply;
  if (selectedTrack >= tempi.length) selectedTrack = tempi.length - 1;
  initTrackColors();
  recomputeTempoBounds();
  suggestionTempi = computeSuggestions(5);
  suggestionTempiBaseOnly = computeSuggestionsBaseOnly(5);
  tapMessage = "Removed track.";
}

void zoomIn() {
  float center = (minTempo + maxTempo) / 2;
  float range = maxTempo - minTempo;
  minTempo = center - range / 8;
  maxTempo = center + range / 8;
  minTempo = max(minTempo, 10);
  maxTempo = min(maxTempo, 1200);
  ensureBaseTemposVisible();
  suggestionTempi = computeSuggestions(5);
  suggestionTempiBaseOnly = computeSuggestionsBaseOnly(5);
  tapMessage = "Zoomed in.";
}

void zoomOut() {
  float center = (minTempo + maxTempo) / 2;
  float range = maxTempo - minTempo;
  minTempo = center - range * 2;
  maxTempo = center + range * 2;
  minTempo = max(minTempo, 10);
  maxTempo = min(maxTempo, 1200);
  ensureBaseTemposVisible();
  suggestionTempi = computeSuggestions(5);
  suggestionTempiBaseOnly = computeSuggestionsBaseOnly(5);
  tapMessage = "Zoomed out.";
}

void ensureBaseTemposVisible() {
  float baseMin = Float.MAX_VALUE;
  float baseMax = -Float.MAX_VALUE;
  for (int i = 0; i < tempi.length; i++) {
    float t = tempi[i];
    if (t > 0) {
      baseMin = min(baseMin, t);
      baseMax = max(baseMax, t);
    }
  }
  if (baseMax < 0) return;
  minTempo = min(minTempo, max(baseMin / 1.15, 10));
  maxTempo = max(maxTempo, min(baseMax * 1.15, 1200));
  minTempo = max(minTempo, 10);
  maxTempo = min(maxTempo, 1200);
}

void mouseWheel(MouseEvent event) {
  if (mouseX < chartLeft() || mouseX > chartRight() || mouseY < topGuideY || mouseY > height) return;
  float mouseTempo = xToTempo(mouseX);
  float factor = event.getCount() > 0 ? 1.2 : 0.8; // down: zoom out, up: zoom in
  float leftDist = mouseTempo - minTempo;
  float rightDist = maxTempo - mouseTempo;
  minTempo = mouseTempo - leftDist * factor;
  maxTempo = mouseTempo + rightDist * factor;
  minTempo = max(minTempo, 10);
  maxTempo = min(maxTempo, 1200);
  ensureBaseTemposVisible();
  suggestionTempi = computeSuggestions(5);
  suggestionTempiBaseOnly = computeSuggestionsBaseOnly(5);
  tapMessage = "Zoomed.";
}

void startTempoEdit() {
  editingMode = "tempo";
  editTrack = selectedTrack;
  tempoInput = "";
  tapMessage = "Type tempo for " + trackNames[selectedTrack] + ", then press Enter.";
}

void startTitleEdit() {
  editingMode = "title";
  editTrack = selectedTrack;
  tempoInput = trackNames[selectedTrack];
  tapMessage = "Type title for " + trackNames[selectedTrack] + ", then press Enter.";
}

void startParamEdit(String mode, int track) {
  editingMode = mode;
  editTrack = track;
  tempoInput = "";
  if (mode.equals("min") || mode.equals("max")) {
    tapMessage = "Type " + mode + " suggestion boundary, then press Enter.";
  } else {
    tapMessage = "Type " + mode + " factor for " + trackNames[track] + ", then press Enter.";
  }
}

void fileSelected(File selection) {
  if (selection == null) {
    tapMessage = "Save canceled.";
    return;
  }
  outputFilename = selection.getAbsolutePath();
  saveTempoFile();
}

void loadFileSelected(File selection) {
  if (selection == null) {
    tapMessage = "Load canceled.";
    return;
  }
  loadTempoFile(selection);
}

boolean hitButton(float x, float y, float bx, float by, float bw, float bh) {
  return x >= bx && x <= bx + bw && y >= by && y <= by + bh;
}

void selectPreviousTrack() {
  selectedTrack = (selectedTrack - 1 + tempi.length) % tempi.length;
  tapTimes.clear();
  tapMessage = "Selected " + trackNames[selectedTrack];
}

void selectNextTrack() {
  selectedTrack = (selectedTrack + 1) % tempi.length;
  tapTimes.clear();
  tapMessage = "Selected " + trackNames[selectedTrack];
}

void handleTap() {
  if (!editingMode.equals("")) {
    tapMessage = "Finish editing first or cancel with Esc.";
    return;
  }

  long now = millis();
  tapTimes.add(now);
  if (tapTimes.size() > 6) {
    tapTimes.remove(0);
  }

  if (tapTimes.size() < 2) {
    tapMessage = "Tap again to measure tempo...";
    return;
  }

  float totalInterval = 0;
  for (int i = 1; i < tapTimes.size(); i++) {
    totalInterval += tapTimes.get(i) - tapTimes.get(i - 1);
  }
  float avgInterval = totalInterval / (tapTimes.size() - 1);
  float bpm = 60000.0 / avgInterval;
  tempi[selectedTrack] = bpm;
  recomputeTempoBounds();
  suggestionTempi = computeSuggestions(5);
  suggestionTempiBaseOnly = computeSuggestionsBaseOnly(5);

  tapMessage = "Tapped " + tapTimes.size() + " times — " + formatTempo(bpm) + " bpm saved to " + trackNames[selectedTrack];
}

void saveTempoFile() {
  String[] lines = new String[tempi.length + 2];
  lines[0] = "# Tempo file";
  lines[1] = "# track,name,tempo,divide,multiply";
  for (int i = 0; i < tempi.length; i++) {
    String tempoText = tempi[i] > 0 ? formatTempo(tempi[i]) : "unset";
    lines[i + 2] = i + "," + csvEscape(trackNames[i]) + "," + tempoText + "," + formatFactor(divideFactors[i]) + "," + formatFactor(multiplyFactors[i]);
  }
  saveStrings(outputFilename, lines);
  showSaveMessage = true;
  saveMessageTimer = millis();
}

void loadTempoFile(File selection) {
  String[] lines = loadStrings(selection);
  if (lines == null) {
    tapMessage = "Could not read file.";
    return;
  }
  ArrayList<Float> loadedTempi = new ArrayList<Float>();
  ArrayList<String> loadedNames = new ArrayList<String>();
  ArrayList<Float> loadedDivide = new ArrayList<Float>();
  ArrayList<Float> loadedMultiply = new ArrayList<Float>();
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith("#")) continue;
    if (trim(lines[i]).length() == 0) continue;
    String[] parts = parseCsvLine(lines[i]);
    if (parts.length >= 3) {
      loadedNames.add(trim(parts[1]));
      String tempoText = trim(parts[2]);
      if (tempoText.equals("unset") || tempoText.equals("-1")) {
        loadedTempi.add(-1.0);
      } else {
        loadedTempi.add(float(tempoText));
      }
      loadedDivide.add(parts.length >= 4 ? parsePositiveFloat(parts[3], 2) : 2.0);
      loadedMultiply.add(parts.length >= 5 ? parsePositiveFloat(parts[4], 2) : 2.0);
    }
  }
  if (loadedTempi.size() > 0) {
    tempi = new float[loadedTempi.size()];
    trackNames = new String[loadedTempi.size()];
    divideFactors = new float[loadedTempi.size()];
    multiplyFactors = new float[loadedTempi.size()];
    for (int i = 0; i < loadedTempi.size(); i++) {
      tempi[i] = loadedTempi.get(i);
      trackNames[i] = loadedNames.get(i);
      divideFactors[i] = loadedDivide.get(i);
      multiplyFactors[i] = loadedMultiply.get(i);
    }
    selectedTrack = 0;
    initTrackColors();
    recomputeTempoBounds();
    suggestionTempi = computeSuggestions(5);
    suggestionTempiBaseOnly = computeSuggestionsBaseOnly(5);
    tapMessage = "Loaded " + loadedTempi.size() + " tracks from file.";
  } else {
    tapMessage = "No valid tempo lines in file.";
  }
}

String csvEscape(String value) {
  String clean = value == null ? "" : value;
  boolean needsQuotes = clean.indexOf(',') >= 0 || clean.indexOf('"') >= 0 || clean.indexOf('\n') >= 0 || clean.indexOf('\r') >= 0;
  clean = clean.replace("\"", "\"\"");
  return needsQuotes ? "\"" + clean + "\"" : clean;
}

String[] parseCsvLine(String line) {
  ArrayList<String> values = new ArrayList<String>();
  String current = "";
  boolean inQuotes = false;
  for (int i = 0; i < line.length(); i++) {
    char ch = line.charAt(i);
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < line.length() && line.charAt(i + 1) == '"') {
          current += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        current += ch;
      }
    } else if (ch == '"') {
      inQuotes = true;
    } else if (ch == ',') {
      values.add(current);
      current = "";
    } else {
      current += ch;
    }
  }
  values.add(current);
  return values.toArray(new String[values.size()]);
}

float parsePositiveFloat(String text, float fallback) {
  try {
    float value = Float.parseFloat(trim(text));
    if (value > 0) return value;
  } catch (Exception e) {
  }
  return fallback;
}

String formatFactor(float factor) {
  if (abs(factor - round(factor)) < 0.01) return str(int(round(factor)));
  return nf(factor, 0, 2);
}

void keyPressed() {
  if (editingMode.equals("")) {
    if (key == 'e' || key == 'E') {
      startTempoEdit();
    }
    return;
  }

  if (key == BACKSPACE) {
    if (tempoInput.length() > 0) {
      tempoInput = tempoInput.substring(0, tempoInput.length() - 1);
    }
    return;
  }

  if (key == ENTER || key == RETURN) {
    if (tempoInput.length() > 0) {
      if (editingMode.equals("title")) {
        String title = trim(tempoInput);
        if (title.length() > 0) {
          trackNames[editTrack] = title;
          tapMessage = "Title saved: " + trackNames[editTrack];
        } else {
          tapMessage = "Invalid title.";
        }
      } else {
        float value = float(tempoInput);
        if (value > 0) {
          if (editingMode.equals("tempo")) {
            tempi[editTrack] = value;
            recomputeTempoBounds();
            tapMessage = "Tempo " + formatTempo(value) + " bpm set for " + trackNames[editTrack];
          } else if (editingMode.equals("divide")) {
            divideFactors[editTrack] = value;
            tapMessage = "Divide factor " + nf(value, 0, 0) + " saved for " + trackNames[editTrack];
          } else if (editingMode.equals("multiply")) {
            multiplyFactors[editTrack] = value;
            tapMessage = "Multiply factor " + nf(value, 0, 0) + " saved for " + trackNames[editTrack];
          } else if (editingMode.equals("min")) {
            minSuggestion = min(value, maxSuggestion - 1);
            minSuggestion = max(minSuggestion, 10);
            tapMessage = "Minimum suggestion set to " + int(minSuggestion);
          } else if (editingMode.equals("max")) {
            maxSuggestion = max(value, minSuggestion + 1);
            tapMessage = "Maximum suggestion set to " + int(maxSuggestion);
          }
          suggestionTempi = computeSuggestions(5);
          suggestionTempiBaseOnly = computeSuggestionsBaseOnly(5);
        } else {
          tapMessage = "Invalid input.";
        }
      }
    }
    editingMode = "";
    editTrack = -1;
    tempoInput = "";
    return;
  }

  if (key == ESC) {
    key = 0;
    editingMode = "";
    editTrack = -1;
    tempoInput = "";
    tapMessage = "Input canceled.";
    return;
  }

  if (editingMode.equals("title")) {
    if (key >= 32 && key != CODED) {
      tempoInput += key;
    }
    return;
  }

  if ((key >= '0' && key <= '9') || key == '.') {
    tempoInput += key;
  }
}

void recomputeTempoBounds() {
  minTempo = Float.MAX_VALUE;
  maxTempo = -Float.MAX_VALUE;
  for (int i = 0; i < tempi.length; i++) {
    considerTempo(tempi[i]);
  }
  if (maxTempo <= minTempo || minTempo <= 0) {
    minTempo = 40;
    maxTempo = 220;
  } else {
    minTempo = max(minTempo / 1.15, 10);
    maxTempo = min(maxTempo * 1.15, 1200);
  }
  ensureBaseTemposVisible();
}

void considerTempo(float t) {
  if (t <= 0) return;
  if (t < minTempo) minTempo = t;
  if (t > maxTempo) maxTempo = t;
}

String formatTempo(float tempo) {
  if (abs(tempo - round(tempo)) < 0.01) return str(int(round(tempo)));
  return nf(tempo, 0, 2);
}

float tempoToX(float tempo) {
  float logMin = log(minTempo);
  float logMax = log(maxTempo);
  float logT = log(tempo);
  float norm = (logT - logMin) / (logMax - logMin);
  return chartLeft() + norm * (chartRight() - chartLeft());
}

float xToTempo(float x) {
  float logMin = log(minTempo);
  float logMax = log(maxTempo);
  float norm = (x - chartLeft()) / (chartRight() - chartLeft());
  float logT = logMin + norm * (logMax - logMin);
  return exp(logT);
}

float chartLeft() {
  return leftMargin + labelWidth;
}

float chartRight() {
  return width - chartRightMargin;
}

float[] computeSuggestions(int count) {
  FloatList occupied = gatherVisibleTempi();
  float[] result = new float[count];
  for (int k = 0; k < count; k++) {
    float bestNorm = findLargestGapMidpoint(occupied);
    result[k] = suggestionNormToTempo(bestNorm);
    occupied.append(bestNorm);
  }
  return result;
}

float[] computeSuggestionsBaseOnly(int count) {
  FloatList occupied = gatherVisibleTempiBaseOnly();
  float[] result = new float[count];
  for (int k = 0; k < count; k++) {
    float bestNorm = findLargestGapMidpoint(occupied);
    result[k] = suggestionNormToTempo(bestNorm);
    occupied.append(bestNorm);
  }
  return result;
}

FloatList gatherVisibleTempi() {
  FloatList occupied = new FloatList();
  for (int i = 0; i < tempi.length; i++) {
    float baseTempo = tempi[i];
    addSuggestionTempoIfVisible(occupied, baseTempo);
    if (baseTempo > 0) {
      float d = max(divideFactors[i], 1);
      float t = baseTempo / d;
      while (t > 0) {
        addSuggestionTempoIfVisible(occupied, t);
        t /= 2;
      }

      float m = max(multiplyFactors[i], 1);
      t = baseTempo * m;
      while (t <= maxTempo) {
        addSuggestionTempoIfVisible(occupied, t);
        t *= 2;
      }
    }
  }
  return occupied;
}

FloatList gatherVisibleTempiBaseOnly() {
  FloatList occupied = new FloatList();
  for (int i = 0; i < tempi.length; i++) {
    addSuggestionTempoIfVisible(occupied, tempi[i]);
  }
  return occupied;
}

void addSuggestionTempoIfVisible(FloatList occupied, float t) {
  float minS = suggestionMinTempo();
  float maxS = suggestionMaxTempo();
  if (t < minS || t > maxS || t <= 0) return;
  float norm = suggestionTempoToNorm(t);
  for (int i = 0; i < occupied.size(); i++) {
    if (circularDistance(norm, occupied.get(i)) < 0.0005) return;
  }
  occupied.append(norm);
}

float suggestionMinTempo() {
  return max(minTempo, minSuggestion);
}

float suggestionMaxTempo() {
  return min(maxTempo, maxSuggestion);
}

float suggestionTempoToNorm(float tempo) {
  float logMin = log(suggestionMinTempo());
  float logMax = log(suggestionMaxTempo());
  if (logMax <= logMin) return 0.5;
  return (log(tempo) - logMin) / (logMax - logMin);
}

float suggestionNormToTempo(float norm) {
  float minS = suggestionMinTempo();
  float maxS = suggestionMaxTempo();
  float logMin = log(minS);
  float logMax = log(maxS);
  if (logMax <= logMin) {
    return (minS + maxS) / 2.0;
  }
  return exp(logMin + norm * (logMax - logMin));
}

float findLargestGapMidpoint(FloatList occupied) {
  if (occupied.size() == 0) return 0.5;
  if (occupied.size() == 1) return (occupied.get(0) + 0.5) % 1.0;
  float[] arr = occupied.array();
  java.util.Arrays.sort(arr);
  float bestGap = -1;
  float bestMid = 0;
  for (int i = 0; i < arr.length; i++) {
    float a = arr[i];
    float b = (i == arr.length - 1) ? arr[0] + 1.0 : arr[i + 1];
    float gap = b - a;
    if (gap > bestGap) {
      bestGap = gap;
      bestMid = (a + gap * 0.5) % 1.0;
    }
  }
  return bestMid;
}

float tempoToNorm(float tempo) {
  float logMin = log(minTempo);
  float logMax = log(maxTempo);
  return (log(tempo) - logMin) / (logMax - logMin);
}

float normToTempo(float norm) {
  float logMin = log(minTempo);
  float logMax = log(maxTempo);
  return exp(logMin + norm * (logMax - logMin));
}

float circularDistance(float a, float b) {
  float d = abs(a - b);
  return min(d, 1.0 - d);
}
