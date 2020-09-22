library(raster)
library(rgdal)
library(stringr)

#where do you want things to go?
baseDir <- '~/mpgPostdoc/projects/forbNiche/data/rasters/environemntal/soil/'
if(!dir.exists(baseDir)){dir.create(baseDir)}

#the following determines the tile to download based on the extent of a template raster extent
template <- raster('~/mpgPostdoc/projects/forbNiche/data/rasters/environemntal/env.tif')
e <- extent(template)
centroid <- matrix(data = c(mean(e[1],e[2]), mean(e[3],e[4])),  1, 2)
epsgs <- make_EPSG()
wgs84 <- epsgs$prj4[which(epsgs$code == '4326')]

sourcePts <- SpatialPoints(coords = centroid, proj4string=crs(template))
targPoints <- spTransform(sourcePts, wgs84)
xcoord <- targPoints@coords[1]# Here you could supply your own centroid by another method 
ycoord <- targPoints@coords[2]

tileInd <- paste0('lat', floor(ycoord), ceiling(ycoord), '_lon', floor(xcoord), ceiling(xcoord), '.tif')

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

for(var in varList){
  for(d in depths){
   fsource <- paste0(serverBase, var, sumStat, d, tileInd) 
   dest <- paste0(baseDir, var, '_', str_remove(d, '/'), '.tif')
   download.file(url = fsource, destfile = dest)
  }
  
}