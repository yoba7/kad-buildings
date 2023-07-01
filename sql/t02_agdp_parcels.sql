select dropTable(NULL,'t02_agdp_parcels',1);

create table t02_agdp_parcels as
select distinct 'WAL' as CD_REGION, parcels.*, st_pointOnSurface(parcels.geometry) as pointOnSurface
from Bpn_CaPa_WAL parcels
UNION
select distinct 'VLA' as CD_REGION, parcels.*, st_pointOnSurface(parcels.geometry) as pointOnSurface
from Bpn_CaPa_VLA parcels
UNION
select distinct 'BXL' as CD_REGION, parcels.*, st_pointOnSurface(parcels.geometry) as pointOnSurface
from Bpn_CaPa_BRU parcels
;
