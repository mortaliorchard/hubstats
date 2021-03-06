// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require select2
//= require hubstats/bootstrap
//= require bootstrap-datepicker
//= require_tree .

/* Below function will run automatically upon refresh. It will do two things:
 *  - format the datepicker settings
 *  - call setDateRange on the datepicker
 */
$(document).ready(function() {
  $('.input-daterange').datepicker({
    "todayHighlight": true,
    "endDate": "Today",
    "todayBtn": true
  });
  setDateRange();
});

/* setDateRange
 * Reads the current cookie (which is currently set as a string with two dates),
 * and sets the dates in the corresponding datepicker.
 */
function setDateRange() {
  var dates;
  var cookie = readCookie("hubstats_dates");

  if (cookie === null || cookie.indexOf("null") > -1) {
    dates = getDefaultDateRange();
  } else {
    dates = readCookie("hubstats_dates");
  }
  var submitButton = document.getElementById("submitDateRange");
  var datesArray = dates.split("~~");

  var start_input = $('.input-daterange').find('[name="start"]');
  var end_input = $('.input-daterange').find('[name="end"]');

  start_input.datepicker('update', new Date(datesArray[0]));
  end_input.datepicker('update', new Date(datesArray[1]));

  /* When the 'Apply' button is pressed for the datepicker, this function will
   * read the datepicker values, assign them to the cookie, and reload the page.
   */
  submitButton.onclick = function() {
    var start_date = start_input.datepicker('getDate');
    var end_date = end_input.datepicker('getDate');
    createCookie("hubstats_dates", start_date + "~~" + end_date, 1);
    window.location.reload();
  };
};

/* createCookie
 * @params - name, value, days
 * Takes a name, value, and number of days and will make a cookie out of those parameters.
 */
function createCookie(name, value, days) {
  if (days) {
    var date = new Date();
    date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
    var expires = "; expires=" + date.toGMTString();
  }
  else var expires = "";
  document.cookie = name + "=" + value + expires + "; path=/";
};

/* readCookie
 * @params - name
 * Takes in the name of a cookie, and will read that cookie, returning either the data
 * from the cookie or null if there is no cookie with that name.
 */
function readCookie(name) {
  var cookieName = name + "=";
  var cookieData = document.cookie.split(';');
  for(var i = 0; i < cookieData.length ; i++) {
    var c = cookieData[i];
    while (c.charAt(0) == ' ') c = c.substring(1, c.length);
    if (c.indexOf(cookieName) == 0) return c.substring(cookieName.length, c.length);
  }
  return null;
};

/* eraseCookie
 * @params - name
 * Creates a new blank cookie.
 */
function eraseCookie(name) {
  createCookie(name, "" , -1);
};

/* getDefaultDateRange
 * Returns a string that is the date two weeks ago, '~~', and today's date with all hours
 * set at midnight.
 */
function getDefaultDateRange() {
  var today = new Date();
  today.setHours(0,0,0,0);
  var twoWeeksAgo = new Date(today);
  twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);
  return twoWeeksAgo + '~~' + today;
};
