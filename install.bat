mkdir f:\HoSDATA\data\db
mkdir f:\HoSDATA\data\log
mkdir f:\HoSDATA\dbconf

rem Saved in f:\HoSDATA\dbconf\mongod.cfg

@echo off

@echo  > f:\HoSDATA\data\log\mongod.log

@echo systemLog:> f:\HoSDATA\dbconf\mongod.cfg
@echo     destination: file >> f:\HoSDATA\dbconf\mongod.cfg
@echo     path: f:\HoSDATA\data\log\mongod.log >> f:\HoSDATA\dbconf\mongod.cfg
@echo storage: >> f:\HoSDATA\dbconf\mongod.cfg
@echo     dbPath: f:\HoSDATA\data\db >> f:\HoSDATA\dbconf\mongod.cfg


rem .\mongod.exe --config "f:\HoSDATA\dbconf\mongod.cfg" --install
rem "f:\Program Files\MongoDB\Server\3.0\bin\mongod.exe" --config "f:\HoSDATA\dbconf\mongod.cfg" --install
rem net start MongoDB