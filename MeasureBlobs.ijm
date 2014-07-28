requires("1.47o");

oldName = getInfo("image.filename");
oldDir = getDirectory("image");

if(oldDir == ""){
  oldDir = getDirectory("home");
}

if(selectionType != 0){
  run("Select None");
}
getSelectionBounds(selX, selY, selW, selH);

if(!is("grayscale")){
  // background subtraction hasn't been carried out first, so do that
  run("Autoscale");
  run("SubtractBlue");
} else {
  oldName = replace(oldName,"^R-B_","");
}

getPixelSize(unit, pw, ph, pd);
if(unit != "mm"){
  exit("Error: scale is not in millimetres (mm). " +
    "Has the scale been set?");
}

selectWindow("R-B_" + oldName);
greyName = "grey_" + oldName;
run("Duplicate...", "title=[" + greyName + "]");

wait(100);
selectWindow("R-B_" + oldName);
setAutoThreshold("Default bright");
setOption("BlackBackground", false);
run("Convert to Mask");
run("Invert");
run("Despeckle");
run("Remove Outliers...", "radius=25 threshold=50 which=Dark");
run("Remove Outliers...", "radius=25 threshold=50 which=Bright");
run("Watershed");
run("Set Measurements...", "area mean standard modal min centroid center perimeter "+
    "bounding fit shape feret's integrated median skewness kurtosis display "+
    "redirect=None decimal=3");
makeRectangle(selX, selY, selW, selH);
run("Clear Results");
run("Analyze Particles...", "size=0.20-Infinity circularity=0-1.00 "+
    "show=[Overlay Outlines] display exclude clear");
if(Overlay.size > 0){
  Overlay.copy();
//  close("R-B_" + oldName);
  selectWindow(oldName);
  Overlay.paste();
  // re-analyse particle regions using greyscale image
  selectWindow(greyName);
  Overlay.paste();
  run("To ROI Manager");
  run("Clear Results");
  selectWindow("Results");
  roiManager("Measure");
  selectWindow("ROI Manager");
  run("Close");
//  close(greyName);
  wait(100);
  selectWindow("Results");
  oldBase = replace(oldName,"(\\.tiff?|\\.jpe?g)$","");
  for (i = 0; i < nResults; i++) {
    setResult("FileName",i,oldBase);
    setResult("BoundX",i,selX);
    setResult("BoundY",i,selY);
    setResult("BoundW",i,selW);
    setResult("BoundH",i,selH);
    setResult("CountMethod",i,"Auto");
    setResult("Location",i,"");
    if(startsWith(oldBase,"SI") || startsWith(oldBase,"Small")){
      setResult("Location",i,"SI");
    }
    if(startsWith(oldBase,"LI") || startsWith(oldBase,"Large")){
      setResult("Location",i,"LI");
    }
    setResult("TumourID",i,i+1);
    setResult("Tumour",i,"");
    setResult("Comments",i,"");
    setResult("Label",i,i+1);
  }
  setOption("ShowRowNumbers", false);
  updateResults();
  if(!File.exists(oldDir + oldBase + "_macroOutput.csv")){
    saveAs("results",oldDir + oldBase + "_macroOutput.csv");
  } else {
    increment = 1;
    while(File.exists(oldDir + oldBase + "_macroOutput." +
                      increment + ".csv")){
      increment++;
    }
    saveAs("results",oldDir + oldBase + "_macroOutput." +
           increment + ".csv");
  }
} else { // no overlay, so don't try to copy it
//  close("R-B_" + oldName);
//  close(greyName);
  selectWindow(oldName);
  showMessage("Blob analysis is finished; no suitable blobs were found.");
}
