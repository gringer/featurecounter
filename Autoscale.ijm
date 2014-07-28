function findMaxima(xx, tolerance){
  // based on "official" findMaxima function from ImageJ 1.48c+
  len = xx.length;
  if (len == 0) {
    return newArray();
  }
  if (tolerance < 0) {
    tolerance = 0;
  }
  maxPositions = Array.copy(xx);
  Array.fill(maxPositions,-1);
  max = xx[0];
  min = xx[0];
  maxPos = 0;
  lastMaxPos = -1;
  leftValleyFound = false;
  maxCount = 0;
  for (jj = 1; jj < len; jj++) {
    val = xx[jj];
    if (val > min + tolerance)
      leftValleyFound = true;
    if (val > max && leftValleyFound) {
      max = val;
      maxPos = jj;
    }
    if (leftValleyFound)
      lastMaxPos = maxPos;
    if (val < max - tolerance && leftValleyFound) {
      maxPositions[maxCount] = maxPos;
      maxCount++;
      leftValleyFound = false;
      min = val;
      max = val;
    }
    if (val < min) {
      min = val;
      if (!leftValleyFound)
	max = val;
    }
  }
  return Array.trim(maxPositions,maxCount);
}

requires("1.44i"); // needed for Array.sort

run("Select None");
ht = getHeight();
wd = getWidth();
oldName = getInfo("image.filename");
fName = "dup_" + oldName;
run("Duplicate...", "title=[" + fName + "]");
selectWindow(fName);
run("Enhance Contrast...", "saturated=0 normalize equalize");
run("8-bit");
setAutoThreshold("Default");
setThreshold(0, 192);
setOption("BlackBackground", false);
run("Convert to Mask");
run("Remove Outliers...", "radius=10 threshold=50 which=Bright");
found = false;
// Calculate image rotation using vertical profile
makeRectangle(wd/3, 100, wd/6, ht-100);
setKeyDown("alt");
p1 = getProfile();
setKeyDown("none");
makeRectangle(wd/3+wd/6, 100, wd/6, ht-100);
setKeyDown("alt");
p2 = getProfile();
setKeyDown("none");
startGr =  p1[floor(p1.length/100)] > p1[(p1.length-1) - floor(p1.length/100)];
ep1 = -1;
ep2 = -1;
for(i = 0; i < p1.length; i++){
      edgeValue = 160; // point where ruler edge should be
      if((ep1 == -1) && ((startGr && p1[i] < edgeValue) ||
                         (!startGr && p1[i] > edgeValue))){
        ep1 = i;
      }
      if((ep2 == -1) && ((startGr && p2[i] < edgeValue) ||
                         (!startGr && p2[i] > edgeValue))){
        ep2 = i;
      }
}
ep1 += 10;
ep2 += 10;
rulerSlope = 0;
if((ep1 != -1) && (ep2 != -1)){
  rulerSlope = (ep2 - ep1) / (wd / 6);
  makeLine(wd/3+wd/12,ep1,wd/3+wd/6+wd/12,ep2);
}
// Calculate scale using line profile
for(i = 0; i < ht; i+= ht/100){
  deviation = wd/6 * rulerSlope;
  makeLine(wd/2-wd/6, i+ht/20-deviation, wd/2+wd/6, i+ht/20+deviation);
  profile = getProfile();
  minLocs = findMaxima(profile, 10);
  Array.sort(minLocs);
  diffs = Array.copy(minLocs);
  if(minLocs.length > 1){
    for(j = 0; j < (minLocs.length-1); j++){
      diffs[j] = minLocs[j+1] - minLocs[j];
    }
    diffs = Array.trim(diffs,minLocs.length-1);
    Array.sort(diffs);
    Array.getStatistics(diffs,min,max,mean,std);
    med = diffs[diffs.length/2];
    cv = abs(std / mean);
    //print("i="+i+",n="+diffs.length+",min="+min+",max="+max+",mean="+mean+
    //      ",med="+med+",std="+std+",cv="+cv*100+"%");
    //Array.print(diffs);
    if((cv < 0.2) && (diffs.length > 30)){
      // print("min="+min+",max="+max+",mean="+mean+
      //  ",med="+med+",std="+std+",cv="+cv*100+"%");
      // Array.print(diffs);
      // print(diffs.length + " peaks between " + minLocs[0] +
      //  " and " + minLocs[minLocs.length-1]);
      selectWindow(oldName);
      makeLine(minLocs[0]+wd/2-wd/6, i+ht/20-deviation,
              (minLocs[minLocs.length-1]-minLocs[0])+wd/2-wd/6,
               i+ht/20+deviation);
      run("Set Scale...", "distance="+(minLocs[minLocs.length-1]-minLocs[0])+
        " known="+diffs.length+" pixel=1 unit=mm");
      selectWindow(fName);
      found = true;
      i += ht; // end outer loop
    }
  }
  //wait(500);
}
close();
if(!found){
  exit("Error: Cannot determine scale, ruler could not be found. " +
    "Are you using a colour image with a horizontal white ruler?");
}
