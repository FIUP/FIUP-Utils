# !/usr/bin/python3
# coding: utf_8

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


""" Parse user-defined calendars and return proper .ics file. """

import argparse
from datetime import datetime

from icalendar import Calendar, Event


class CalendarEvent(object):
    def __init__(self, name, description, date):
        object.__init__(self)

        self.name = name.strip()
        self.description = description.strip()
        self.date = date

    def __str__(self):
        return self.name + " (" + self.description + ") " + str(self.date)


def get_events(infile):
    """ Parse input file to get info about events. """
    events = []
    with open(infile, "r") as f:
        lines = f.readlines()  # get list of lines
        for l in lines:
            tokens = l.split(",")  # it's a csv file
            new_event = CalendarEvent(tokens[0], tokens[2], datetime.strptime(tokens[1].strip(), "%d/%m/%Y"))
            events.append(new_event)
            print(str(new_event))
    return events


def convert_to_calendar(events):
    """ For each event , parse it and convert to vcard, then convert the whole to a calendar .ics. """
    c = Calendar()
    for event in events:
        e = Event()
        e.add("summary", str(event.name).title())  # set name
        e.add("description", str(event.description))  # set description
        e["dtstart"] = str(event.date.date()).replace("-", "")  # from datetime to calendar format
        e["dtend"] = str(event.date.date()).replace("-", "")
        e.add("rrule", {"freq": "yearly"})  # repeat weekly and until date
        # e.add("exdate", str(event.date.year) + str(event.date.month) + str(event.date.day))  # repeat event NOT in this date
        c.add_component(e)
    return c

if __name__ == '__main__':
    parser = argparse.ArgumentParser(usage="-i <input csv file> -o <output file>\n-h for full usage")
    parser.add_argument("-i", dest="inp", help="coma separated values file to parse", required=True)
    parser.add_argument("-o", dest="out", help="file to write calendar on", required=True)
    args = parser.parse_args()
    
    args.inp = str(args.inp)
    args.out = str(args.out)
    
    calendar = convert_to_calendar(get_events(args.inp))
    with open(args.out, "wb") as f:
        f.write(calendar.to_ical())
