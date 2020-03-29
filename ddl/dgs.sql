create schema dgs;

-- daily municipal data placeholder
create table dgs.daily_mun (
	id serial not null,
	objectid int4 not null,
	cases int4 not null default 0,
	"date" timestamp not null,
	constraint pk_daily_mun primary key (id)
);

-- municipal views
create or replace view dgs.v_daily_mun
as select row_number() over(order by b.date) as id,
    b.objectid,
    a.concelho,
    b.cases,
    b.cases - (lag(b.cases, 1) over (
   				partition by a.concelho
   				order by a.concelho, b."date")) as cases_progress,
    b.date,
    a.geom
   from geo.pt_mun a
     join dgs.daily_mun b on a.objectid = b.objectid
   order by 3,6;

create materialized view dgs.mv_daily_mun_last
as select b.objectid,
   a.concelho,
   b.cases,
   z.cases_progress,
   a.geom
  from geo.pt_mun a
    join dgs.daily_mun b on a.objectid = b.objectid
    join lateral (
    	select vdm."date", vdm.cases_progress from dgs.v_daily_mun vdm where vdm.concelho = a.concelho
    ) z on b."date" = z."date"
  where b.date > now() - interval '1d'
  order by 2;

-- regional mv placeholder
create materialized view dgs.region_stats as
  select b.objectid,
    a.datarel,
    min(a.dist_casosconf) as confirmed,
    min(a.dist_obitos) as deaths,
    min(a.dist_recuperados) as recovered
   from esri.casos_regiao a
     join geo.pt_regions b on st_intersects(st_buffer(st_transform(a.geom, 3763), 10000::double precision), st_makevalid(b.geom))
  group by 1, 2;

-- daily export view
create or replace view dgs.v_region_stats_export as
	select * from dgs.region_stats where datarel > now() - interval '1d';

create or replace view dgs.v_daily_regions
as select row_number() over(order by a.datarel) as id,
    b.name,
    a.datarel,
    a.confirmed,
    a.deaths,
    a.recovered,
    b.geom
   from dgs.region_stats a
     join geo.pt_regions b on a.objectid = b.objectid;

create or replace view dgs.v_daily_regions_last
as select b.name,
  a.confirmed,
  a.confirmed_progress,
  a.deaths,
  a.deaths_progress,
  a.recovered,
  a.recovered_progress,
  b.geom
 from dgs.v_daily_regions a
   join geo.pt_regions b on a."name" like b."name"
 where a.datarel > now() - interval '1d';
