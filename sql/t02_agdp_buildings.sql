select dropTable(NULL,'t02_agdp_buildings',1);

create table t02_agdp_buildings as
select distinct 'KAD' as cd_source, MD5Checksum(buildings.geometry) as id_building, buildings.geometry, st_pointOnSurface(buildings.geometry) as pointOnSurface
from Bpn_CaBu buildings
UNION
select distinct 'REG' as cd_source, MD5Checksum(buildings.geometry) as id_building, buildings.geometry, st_pointOnSurface(buildings.geometry) as pointOnSurface
from Bpn_ReBu buildings;

create table t02_agdp_buildings_duplicates as
select id_building
from t02_agdp_buildings
group by 1
having count(*)>1;

delete from t02_agdp_buildings
where id_building in ( select distinct id_building from t02_agdp_buildings_duplicates) and cd_source='KAD';

create unique index i02_agdp_buildings on t02_agdp_buildings(id_building);
