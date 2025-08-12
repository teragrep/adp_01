import os
import pytz
import datetime
timezone = pytz.timezone('Europe/Helsinki')
basepath = "/srv/data/spool"
host="index-with-duplicates.{{.Values.ipa.domain}}"
tag="index-with-duplicates"
# Starting timestamp
starting_epoch = 1696464000 # Your time zone: Thursday, October 5, 2023 3:00:00 GMT+03:00 DST
for hour in range(1,4):
    # Bump timestamp by n hours
    new_epoch = starting_epoch + hour*3600
    # Get epoch hour, floored
    epoch_hour = new_epoch - new_epoch%3600
    timestamp = datetime.datetime.fromtimestamp(new_epoch, timezone)
    dirname=f"{basepath}/{host}/{timestamp.year}/{str(timestamp.month).zfill(2)}/{str(timestamp.day).zfill(2)}"
    filename=f"{dirname}/{tag}-@{epoch_hour}-{timestamp.year}{str(timestamp.month).zfill(2)}{str(timestamp.day).zfill(2)}{str(timestamp.hour).zfill(2)}.log"
    if not os.path.exists(dirname):
        os.makedirs(dirname)
    with open(filename, "a+") as fh:
        for ignored in range(1,4):
            fh.write(f"<134>1 {timestamp.isoformat('T')} {host} {tag} - - - This is duplicated event #{hour}\n")
