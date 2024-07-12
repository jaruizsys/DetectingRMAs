SELECT 
	m.compID as companyId,
	u.CUnits_id as unitId,
    u.imei,
    u.USN as esn,
    m.manufacturer,
    ut.unittype as unitType,
    uv.version,
    IF(sta.unitstatus_id = 6, 1, 0) as isRMA,
    -- COALESCE((select 1 from platformmanager.refurbishedUnits ru where ru.unitId = u.CUnits_id LIMIT 1), 0) enabledToReuse,
    -- sta.unitstatus_name as statusName, 
    -- u.createdOn,
    -- u.installedOn,
    -- u.statusUpdatedOn,
    IF(sta.unitstatus_id = 6, 
		(
			FLOOR(DATEDIFF(u.statusUpdatedOn, u.createdOn))
        ),
        (
			FLOOR(DATEDIFF('2024-07-01', u.createdOn))
        )
	) as liveAgeDays,
    -- lr.lastMessageTime,
    COALESCE((SELECT AVG(`value`) FROM platformmanager.maintenanceWarnings mw WHERE mw.unitId = u.CUnits_id AND mw.`date` BETWEEN '2023-01-01' AND '2024-07-01' and mw.warning = 'HDOPQuality'), 0) as HDOPQuality,
    COALESCE((SELECT AVG(`value`) FROM platformmanager.maintenanceWarnings mw WHERE mw.unitId = u.CUnits_id AND mw.`date` BETWEEN '2023-01-01' AND '2024-07-01' and mw.warning = 'ExcessiveEvents'), 0) as ExcessiveEvents,
    COALESCE((SELECT AVG(`value`) FROM platformmanager.maintenanceWarnings mw WHERE mw.unitId = u.CUnits_id AND mw.`date` BETWEEN '2023-01-01' AND '2024-07-01' and mw.warning = 'LowBattery'), 0) as LowBattery,
    COALESCE((SELECT AVG(`value`) FROM platformmanager.maintenanceWarnings mw WHERE mw.unitId = u.CUnits_id AND mw.`date` BETWEEN '2023-01-01' AND '2024-07-01' and mw.warning = 'IgnitionOnEventsAbnormal'), 0) as IgnitionOnEventsAbnormal,
    COALESCE((SELECT AVG(`value`) FROM platformmanager.maintenanceWarnings mw WHERE mw.unitId = u.CUnits_id AND mw.`date` BETWEEN '2023-01-01' AND '2024-07-01' and mw.warning = 'PowerDisconnect'), 0) as PowerDisconnect,
    COALESCE((SELECT AVG(`value`) FROM platformmanager.maintenanceWarnings mw WHERE mw.unitId = u.CUnits_id AND mw.`date` BETWEEN '2023-01-01' AND '2024-07-01' and mw.warning = 'LowSatellites'), 0) as LowSatellites,
    COALESCE((SELECT AVG(`value`) FROM platformmanager.maintenanceWarnings mw WHERE mw.unitId = u.CUnits_id AND mw.`date` BETWEEN '2023-01-01' AND '2024-07-01' and mw.warning = 'DailyOdometerExceeded'), 0) as DailyOdometerExceeded,
    COALESCE((SELECT AVG(`value`) FROM platformmanager.maintenanceWarnings mw WHERE mw.unitId = u.CUnits_id AND mw.`date` BETWEEN '2023-01-01' AND '2024-07-01' and mw.warning = 'WirelessSignal'), 0) as WirelessSignal,
    COALESCE((SELECT AVG(`value`) FROM platformmanager.maintenanceWarnings mw WHERE mw.unitId = u.CUnits_id AND mw.`date` BETWEEN '2023-01-01' AND '2024-07-01' and mw.warning = 'MaintenanceLimitExceeded'), 0) as MaintenanceLimitExceeded,
    COALESCE((SELECT AVG(`value`) FROM platformmanager.maintenanceWarnings mw WHERE mw.unitId = u.CUnits_id AND mw.`date` BETWEEN '2023-01-01' AND '2024-07-01' and mw.warning = 'LateEvents'), 0) as LateEvents,
    COALESCE((SELECT AVG(`value`) FROM platformmanager.maintenanceWarnings mw WHERE mw.unitId = u.CUnits_id AND mw.`date` BETWEEN '2023-01-01' AND '2024-07-01' and mw.warning = 'CommLost'), 0) as CommLost,
    COALESCE((SELECT AVG(`value`) FROM platformmanager.maintenanceWarnings mw WHERE mw.unitId = u.CUnits_id AND mw.`date` BETWEEN '2023-01-01' AND '2024-07-01' and mw.warning = 'DailyEngineHoursExceeded'), 0) as DailyEngineHoursExceeded
FROM
	fleet.CUnits u 
    INNER JOIN fleet.masterlist m ON m.compID = u.compID
    INNER JOIN inventory.unitversion uv ON uv.unitversion_id = u.unitversion_id
    INNER JOIN inventory.unittype ut ON ut.unittype_id = uv.unittype_id
    INNER JOIN inventory.unitmanufacturer m ON m.unitmanufacturer_id = ut.unitmanufacturer_id
    LEFT JOIN fleet.unitstatus sta ON sta.unitstatus_id = u.unitstatus_id
    LEFT JOIN fleet.lastReading lr ON lr.id = CONCAT(u.compID, '-', u.CUnits_id)
WHERE 
	u.unitstatus_id IN(1)
    AND EXISTS(
		SELECT * 
        FROM platformmanager.maintenanceWarnings mw 
        WHERE mw.unitId = u.CUnits_id
			AND mw.`date` BETWEEN '2023-01-01' AND '2024-07-01'
    )
ORDER BY lastMessageTime DESC
LIMIT 2000;