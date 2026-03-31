from firecrawl import Firecrawl
from firecrawl.v2.types import ScrapeOptions

app = Firecrawl(api_key="fc-2f2628ca57fd4dc496f09a8d9ee5c943")

scrape_opts = ScrapeOptions(
    only_main_content=False,
    max_age=172800000,
    parsers=["pdf"],
    formats=["markdown"]
)

crawl_result = app.crawl(
    "housing-osa.ncku.edu.tw/",
    sitemap="include",
    crawl_entire_domain=False,
    limit=10,
    scrape_options=scrape_opts
)

print(crawl_result)

#This script is not always in your side,be care for below resource to modify it:
#https://www.firecrawl.dev/
