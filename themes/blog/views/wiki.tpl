<%
from sushy.utils import utc_date

def fuzzy_time(date):
    intervals = {
        '00:00-00:59': 'late night',
        '01:00-03:59': 'in the wee hours',
        '04:00-06:59': 'by dawn',
        '07:00-08:59': 'breakfast',
        '09:00-12:29': 'morning',
        '12:30-14:29': 'lunchtime',
        '14:30-16:59': 'afternoon',
        '17:00-17:29': 'tea-time',
        '17:30-18:59': 'late afternoon',
        '19:00-20:29': 'evening',
        '20:30-21:29': 'dinnertime',
        '21:30-22:29': 'night',
        '22:30-23:59': 'late night'
    }
    when = date.strftime("%H:%M")
    for i in intervals.keys():
        (l,u) = i.split('-')
        if l <= when and when <= u:
            return intervals[i]
        end
    end
    return "sometime"
end

if "from" in headers:
    metadata = headers["from"]
else:
    metadata = "Unknown"
end

if "date" in headers:
    post_date = utc_date(headers["date"], "")
    if post_date != "":
      metadata = metadata + " - %s (%s)" % (post_date.strftime("%B %d, %Y"), fuzzy_time(post_date))
    end
end
%>

<div class="container blog">
    <div class="row">
        <article class="twelve columns">
            <header>
                <h1 class="post-heading">{{!headers["title"]}}</h1>
                <div class="metadata">
                    By {{!metadata}}
                </div>
            </header>
            <div class="content">
                {{!body}}
            </div>
        </article>
%include('seealso')
    </div>
</div>
%rebase('layout', base_url=base_url, headers=headers, pagename=pagename, seealso=seealso, site_name=site_name, scripts=['eventsource.js','utils.js','app.js'])