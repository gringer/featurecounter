// subtract the blue channel from an image
run("Select None");
oldName = getInfo("image.filename");
fName = "dup_" + oldName;
run("Duplicate...", "title=[" + fName + "]");
selectWindow(fName);

ht = getHeight();
wd = getWidth();
// Get histogram profile from an area that doesn't include the ruler
makeRectangle(0, ht/6, wd, ht/3);
setRGBWeights(1,0,0); // red value
getStatistics(tArea, rMean, tMin, tMax, rStd, tHist);
setRGBWeights(0,1,0); // green value
getStatistics(tArea, gMean, tMin, tMax, gStd, tHist);
setRGBWeights(0,0,1); // blue value
getStatistics(tArea, bMean, tMin, tMax, bStd, tHist);
run("Select None");


run("Split Channels");
selectWindow(fName + " (green)");
close();
selectWindow(fName + " (red)");
run("Enhance Contrast...", "saturated=0 normalize equalize");
selectWindow(fName + " (blue)");
run("Enhance Contrast...", "saturated=0 normalize equalize");
imageCalculator("Subtract create", fName + " (red)",fName + " (blue)");
selectWindow(fName + " (red)");
close();
selectWindow(fName + " (blue)");
close();
selectWindow("Result of " + fName + " (red)");
rename("R-B_" + oldName);
