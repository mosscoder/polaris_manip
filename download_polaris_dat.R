library(raster)
library(rgdal)
library(stringr)

#where do you want things to go?
baseDir <- '~/mpgPostdoc/projects/forbNiche/data/rasters/environemntal/soil/'
if(!dir.exists(baseDir)){dir.create(baseDir)}

#the following determines the tiles to download based on the extent of a template raster extent
template <- raster('~/mpgPostdoc/projects/forbNiche/data/rasters/environemntal/env.tif')
e <- as(extent(template), 'SpatialPolygons')
proj4string(e) <- crs(template)
eLatLon <- extent(spTransform(e, "+proj=longlat +datum=WGS84 +no_defs +type=crs"))

tileRas <- raster(xmn = floor(eLatLon[1]),
       xmx = ceiling(eLatLon[2]),
       ymn = floor(eLatLon[3]), 
       ymx = ceiling(eLatLon[4]), 
       res = 1)

tileCentroids <- rasterToPoints(tileRas)

tileInds <- character(nrow(tileCentroids))

for(i in seq_along(tileInds)) {
  xcoord <- tileCentroids[i,1]
  ycoord <- tileCentroids[i,2]
  tileInds[i] <-
    paste0(
      'lat',
      floor(ycoord),
      ceiling(ycoord),
      '_lon',
      floor(xcoord),
      ceiling(xcoord),
      '.tif'
    )
}

#Or just provide a centroid 
# xcoord <- -114.5
# ycoord <- 46.5
# tileInds <- paste0(lat', floor(ycoord), ceiling(ycoord), '_lon', floor(xcoord), ceiling(xcoord), '.tif')

serverBase <- 'http://hydrology.cee.duke.edu/POLARIS/PROPERTIES/v1.0/'

varList <- c('alpha', #scale parameter inversely proportional to mean pore diameter (van genuchten), log10(kPa-1)
             'bd', #bulk density, g/cm3
             'clay', #clay percentage, %
             'hb', #bubbling pressure (brooks-corey), log10(kPa)
             'ksat', #saturated hydraulic conductivity, log10(cm/hr)
             'lambda', #pore size distribution index (brooks-corey), N/A
             'n', #measure of the pore size distribution (van genuchten), N/A
             'om', #organic matter, log10(%)
             'ph', #soil pH in H2O, N/A
             'sand', #sand percentage, %
             'silt', #silt percentage, %
             'theta_r', #residual soil water content, m3/m3
             'theta_s') #saturated soil water content, m3/m3

depths <- c('0_5/', #all the depth ranges 
            '5_15/',
            '15_30/',
            '30_60/',
            '60_100/',
            '100_200/'
            )

sumStat <- '/mean/' #also mode, p5, p50, p95 (p = percentile)

tdir <- tempdir()

for(var in varList) {
  for (d in depths) {
    for (ind in tileInds) {
      fsource <- paste0(serverBase, var, sumStat, d, ind)
      tdest <- paste0(tdir, '/', ind)
      download.file(url = fsource, destfile = tdest)
      rasProc <- raster(tdest)
      rasProc <- projectRaster(rasProc, template)
      rasProc <- crop(rasProc, template)
      writeRaster(rasProc, tdest, overwrite = TRUE)
    }
      toMos <- list.files(tdir, pattern = "*.tif", full.names = TRUE)
      st <- stack(lapply(FUN = raster, X = toMos))
      out <- max(st, na.rm = TRUE )
      writeRaster(out , paste0(baseDir, '/', var, '_', str_remove(d, '/'), '.tif'), overwrite = TRUE)
      file.remove(toMos)
  }
}