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

create or replace view dgs.v_daily_mun_last
as select b.objectid,
 a.concelho,
 b.cases,
 b.cases_progress,
 case
	   when b.cases != 0 and b.cases_progress != 0 then
		   round(b.cases_progress*100/b.cases::decimal, 1)
 	   else
	   	   null
 end as cases_progress_perc,
 a.geom
from geo.pt_mun a
  join dgs.v_daily_mun b on a.objectid = b.objectid
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
  case
	   when a.confirmed != 0 and a.confirmed_progress != 0 then
		   round(a.confirmed_progress*100/a.confirmed::decimal, 1)
     else
	 	   null
  end as confirmed_progress_perc,
  a.deaths,
  a.deaths_progress,
  case
	   when a.deaths != 0 and a.deaths_progress != 0 then
		   round(a.deaths_progress*100/a.deaths::decimal, 1)
     else
	 	   null
  end as deaths_progress_perc,
  a.recovered,
  a.recovered_progress,
  case
	   when a.recovered != 0 and a.recovered_progress != 0 then
		   round(a.recovered_progress*100/a.recovered::decimal, 1)
   	 else
	   	 null
  end as recovered_progress_perc,
  b.geom
 from dgs.v_daily_regions a
   join geo.pt_regions b on a."name" like b."name"
 where a.datarel > now() - interval '1d';
