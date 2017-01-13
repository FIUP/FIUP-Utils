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


""" Scrape Unipd dpt of CS to get information about exams and convert to .ics file to add to calendars. """

import argparse
from datetime import datetime

from bs4 import BeautifulSoup
from hal.internet.web import Webpage
from icalendar import Calendar, Event

URL = "http://informatica.math.unipd.it/cgi-bin/RetrieveListExamsAjax.cgi?laurea=[INF-T]"
EXAM_DIVISOR = "<li><strong>"


class Exam(object):
    def __init__(self, name, description, date):
        object.__init__(self)

        self.name = name.strip()
        self.description = description.strip()
        self.date = date


def get_exams():
    """ Get source page and parse to get info about exams. """
    source_page = Webpage(URL).get_html_source()  # get html source page
    source_page = source_page.replace("\t", "").replace("\n", "").replace("  ", "")  # remove line breaks

    exams = []
    courses = source_page.split(EXAM_DIVISOR)[1:]  # first item is not an exam
    for c in courses:
        c = EXAM_DIVISOR + c  # restore divisor
        s = BeautifulSoup(c)  # create soup
        name = s.find_all("strong")[0].text

        for i in range(len(s.find_all("ul")[0].find_all("li"))):
            e = s.find_all("ul")[0].find_all("li")[i]  # get element
            description = str(i + 1) + " appello - " + str(e.text.strip())  # parse description and add number of exam
            date = e.text.strip().split("-")[1]  # get raw date
            date = datetime.strptime(date.strip().split(",")[0], "%d/%m/%Y")
            exams.append(Exam(name, description, date))

    return exams


def convert_to_calendar(exams):
    """ For each exam in exams, parse it and convert to vcard, then convert the whole to a calendar .ics. """
    c = Calendar()
    for exam in exams:
        e = Event()
        e.add("summary", str(exam.name).title())  # set name
        e.add("description", str(exam.description))  # set description
        e["dtstart"] = str(exam.date.date()).replace("-", "")  # from datetime to calendar format
        e["dtend"] = str(exam.date.date()).replace("-", "")
        # event.add("rrule", {"freq": "weekly", "until": "20161214"})  # repeat weekly and until date
        # e.add("exdate", str(exam.date.year) + str(exam.date.month) + str(exam.date.day))  # repeat event NOT in this date
        c.add_component(e)
    return c

if __name__ == '__main__':
    parser = argparse.ArgumentParser(usage="-o <output file>\n-h for full usage")
    parser.add_argument("-o", dest="out", help="file to write calendar on", required=True)
    args = parser.parse_args()

    args.out = str(args.out)
    calendar = convert_to_calendar(get_exams())
    with open(args.out, "wb") as f:
        f.write(calendar.to_ical())
