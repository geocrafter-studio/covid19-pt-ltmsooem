# covid19-pt-ltmsooem
Portuguese COVID19 geospatial curated dataset

***DISCLAIMER: The data we share is harvested and curated from the official Portuguese national health organization [dashboard](https://covid19.min-saude.pt/ponto-de-situacao-atual-em-portugal/) and related services***

Challenged by [Ramiz Sami](https://www.linkedin.com/in/ramizsami/) the author of [thecoronamap.com](https://www.thecoronamap.com) in order to deliver more insight information at country specific level we started to inspect the information provided by Portuguese national health organization [DGS](https://www.dgs.pt).

This is our tentative to curate Portuguese COVID19 datasets provided by Portuguese health authorities and make it more open and 'geo-friendly'!

### Brief datamodel description
* `daily` contains all daily filtered data in CSV format provided at different administrative levels
   * `PT_mun_<date>.csv` for municipal level data
   * `PT_regions_<date>.csv` for health regions level data
* `geodata` contains all administrative areas where report data is generated. We assume you ingest this data into schema `geo` on database level.
* `ddl` contains the backbone of the data model
  * `dgs` the main schema where data is curated for geospatial usage
  * `esri` placeholder schema to collect in bulk some daily data from official services
  * `geo` the geospatial administrative level data to be used
* Municipal level
  * `dgs.v_daily_mun` contains all daily active cases per municipal area
  * `dgs.v_daily_mun_last` same as above but filtered for previous day
* Regional level
  * `dgs.v_daily_regions` contains all daily active cases per region area
  * `dgs.v_daily_regions_last` same as above but filtered for previous day

### How to update my local dataset?
* Regional level
  * Grab the file(s) `PT_regions_<date>.csv` and ingest it directly on table `esri.casos_regiao` mapping only the needed columns (`objectid`, `datarel`, `dist_casosconf`, `dist_obitos`, `dist_recuperados`)
  * Refresh the materialized view `dgs.region_stats`
* Municipal level
  * Grab the file(s) `PT_mun_<date>.csv` and ingest it directly on table `dgs.daily_mun` mapping only the available columns (`objectid`, `cases`). Update date field on table `dgs.daily_mun` using an update statement (`update dgs.daily_mun set date = '<new-date-here> 00:00:00' where date is null;`)
