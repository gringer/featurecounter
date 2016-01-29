// subtract the blue channel from an image
run("Select None");
oldName = getInfo("image.filename");
fName = "dup_" + oldName;
run("Duplicate...", "title=[" + fName + "]");

selectWindow(fName);
ht = getHeight();
wd = getWidth();
// Get mean, SD from an area that doesn't include the ruler
// [i.e make the background colour consistent]
makeRectangle(0, ht/4, wd, ht/2);
//setRGBWeights(1,0,0); // red value
//getStatistics(tArea, rMean, tMin, tMax, rSD, tHist);
//setRGBWeights(0,1,0); // green value
//getStatistics(tArea, gMean, tMin, tMax, gSD, tHist);
//setRGBWeights(0,0,1); // blue value
//getStatistics(tArea, bMean, tMin, tMax, bSD, tHist);
run("Select None");
//setMinAndMax(rMean-6*rSD,rMean+4*rSD,4);
//setMinAndMax(gMean-6*gSD,gMean+4*rSD,2);
//setMinAndMax(bMean-6*bSD,bMean+3*bSD,1);

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
selectWindow("R-B_" + oldName);
