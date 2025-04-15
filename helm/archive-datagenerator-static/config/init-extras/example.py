import os
import pytz
import datetime
timezone = pytz.timezone('Europe/Helsinki')
basepath = "/srv/data/spool"
host="example.{{.Values.ipa.domain}}"
tag="example"
epoch = 1696464000 # Your time zone: Thursday, October 5, 2023 3:00:00 GMT+03:00 DST
for message in range(1,4):
    for hour in range(1,4):
        timestamp = datetime.datetime.fromtimestamp(epoch + hour*3600, timezone) # bumps logs by n hours
        dirname=f"{basepath}/{host}/{timestamp.year}/{str(timestamp.month).zfill(2)}/{str(timestamp.day).zfill(2)}"
        filename=f"{dirname}/{tag}-{timestamp.year}{str(timestamp.month).zfill(2)}{str(timestamp.day).zfill(2)}{str(timestamp.hour).zfill(2)}.log"
        if not os.path.exists(dirname):
            os.makedirs(dirname)
        with open(filename, "a+") as fh:
            fh.write(f"<134>1 {timestamp.isoformat('T')} {host} {tag} - - - This is an event for {host}-{tag} for hour {hour} #{message}\n")
