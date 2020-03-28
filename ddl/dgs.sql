CREATE SCHEMA dgs;

-- daily municipal data placeholder
CREATE TABLE dgs.daily_mun (
	id serial NOT NULL,
	objectid int4 NOT NULL,
	cases int4 NOT NULL DEFAULT 0,
	"date" timestamp NOT NULL,
	CONSTRAINT pk_daily_mun PRIMARY KEY (id)
);

-- municipal views
CREATE OR REPLACE VIEW dgs.v_daily_mun
AS SELECT row_number() over(order by b.date) as id,
    b.objectid,
    a.concelho,
    b.cases,
    b.cases - (lag(b.cases, 1) over (
   				PARTITION BY a.concelho
   				ORDER BY a.concelho, b."date")) as cases_progress,
    b.date,
    a.geom
   FROM geo.pt_mun a
     JOIN dgs.daily_mun b ON a.objectid = b.objectid
   ORDER BY 3,6;

CREATE OR REPLACE VIEW dgs.v_daily_mun_last
AS SELECT b.objectid,
   a.concelho,
   b.cases,
   z.cases_progress,
   a.geom
  FROM geo.pt_mun a
    JOIN dgs.daily_mun b ON a.objectid = b.objectid
    join lateral (
    	select vdm."date", vdm.cases_progress from dgs.v_daily_mun vdm where vdm.concelho = a.concelho
    ) z on b."date" = z."date"
  where b.date > now() - interval '1d'
  order by 2;

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
AS SELECT row_number() over(order by a.datarel) as id,
    b.name,
    a.datarel,
    a.confirmed,
    a.deaths,
    a.recovered,
    b.geom
   FROM dgs.region_stats a
     JOIN geo.pt_regions b ON a.objectid = b.objectid;

CREATE OR REPLACE VIEW dgs.v_daily_regions_last
AS SELECT b.name,
   a.confirmed,
   a.deaths,
   a.recovered,
   b.geom
  FROM dgs.region_stats a
    JOIN geo.pt_regions b ON a.objectid = b.objectid
  where a.datarel > now() - interval '1d';
