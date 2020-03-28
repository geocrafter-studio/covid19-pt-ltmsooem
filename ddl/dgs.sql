CREATE SCHEMA dgs;

-- daily municipal data placeholder
CREATE TABLE dgs.daily_mun (
	id serial NOT NULL,
	objectid int4 NOT NULL,
	cases int4 NULL,
	"date" timestamp NOT NULL,
	CONSTRAINT pk_daily_mun PRIMARY KEY (id)
);

-- municipal views
CREATE OR REPLACE VIEW dgs.v_daily_mun
AS SELECT b.objectid,
    a.concelho,
    b.cases,
    b.date,
    a.geom
   FROM geo.pt_mun a
     JOIN dgs.daily_mun b ON a.objectid = b.objectid;

CREATE OR REPLACE VIEW dgs.v_daily_mun_agg
AS SELECT b.objectid,
   a.concelho,
   sum(b.cases) AS total_cases,
   a.geom
  FROM geo.pt_mun a
    JOIN dgs.daily_mun b ON a.objectid = b.objectid
 GROUP BY b.objectid, a.concelho, a.geom;

-- regional MV placeholder
CREATE MATERIALIZED VIEW dgs.region_stats AS
  SELECT b.objectid,
    a.datarel,
    min(a.dist_casosconf) AS confirmed,
    min(a.dist_obitos) AS deaths,
    min(a.dist_recuperados) AS recovered
   FROM esri.casos_regiao a
     JOIN geo.pt_regions b ON st_intersects(st_buffer(st_transform(a.geom, 3763), 10000::double precision), st_makevalid(b.geom))
  group by b.objectid, a.datarel;

CREATE OR REPLACE VIEW dgs.v_daily_regions
AS SELECT b.name,
    a.datarel,
    a.confirmed,
    a.deaths,
    a.recovered,
    b.geom
   FROM dgs.region_stats a
     JOIN geo.pt_regions b ON a.objectid = b.objectid;

CREATE OR REPLACE VIEW dgs.v_daily_regions_agg
AS SELECT b.name,
   sum(a.confirmed) AS confirmed,
   sum(a.deaths) AS deaths,
   sum(a.recovered) AS recovered,
   b.geom
  FROM dgs.region_stats a
    JOIN geo.pt_regions b ON a.objectid = b.objectid
 GROUP BY b.name, b.geom;
