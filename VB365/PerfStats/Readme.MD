- [User Story](#user-story)
- [Explanation of performance markers](#explanation-of-performance-markers)
  - [Log Example](#log-example)
- [Workflow](#workflow)
- [Rate calculations](#rate-calculations)
  - [Log Example](#log-example-1)
  - [Calculations](#calculations)
- [Target vs Source bottleneck](#target-vssource-bottleneck)
- [Total data explanation](#total-data-explanation)
  - [Non-zero](#non-zero)
  - [Zero](#zero)
  - [Sync time investigation](#sync-time-investigation)
- [Build rate statistics for performance related cases](#build-rate-statistics-for-performance-related-cases)
## User Story
- As a support engineer working with M365 performance case
- I would like to know how to read M365 logs efficiently
- So that I could provide the explanation of what exactly takes up the most time and what measures I can take to help with poor performance.

## Explanation of performance markers
### Log Example
One can find the following lines in the log files:
```
[11.04.2022 08:05:05]   83 (4744)  Download completed: /sites/CYMI/Teste/test.pdf, 
URI: https://tenant.sharepoint.com/sites/CYMI/_layouts/download.aspx?UniqueId=44617414-83cc-5cff-8d9b-1ad55a0edd34&ApiVersion=2.0, 
size: 2802894, transferred: 2802894

[11.04.2022 08:05:06]   83 (4744)  Download completed
[11.04.2022 08:05:06]   83 (4744)   Download time: 12,3083849
[11.04.2022 08:05:06]   83 (4744)   Saving time: 31,1991614
[11.04.2022 08:05:06]   83 (4744) Marking deleted items: 223213 - 223232...
[11.04.2022 08:05:36]   83 (4744)  Total data: 18088575
[11.04.2022 08:05:36]   83 (4744)   Receive rate: 26887 B/s
[11.04.2022 08:05:36]   83 (4744)   Saving rate : 160559 B/s
```

## Workflow
1. Decide whether item needs to be backed up
   1. Display **Sync time** - the overall time it takes to back up an item. It is always increasing during the backup. Displays how long it takes to check whether an item in the list should be backed up (including its metadata - fields, contents, web parts, attachments)
2. Save items to the database without content
   1. Display **Saving time** - time to save items to the database without content (fields, contents, web parts, attachments BUT information about all these metadata will be saved). It shows accumulated value, e.g.
   ```
   [11.04.2022 00:09:14]   78 (20176) Requesting changed item versions properties..
   [11.04.2022 00:09:19]   78 (20176)  Saving item: /sites/CYMI/Teste/test.xlsx, version: 0, label: 2.0..
   [11.04.2022 00:09:21]   78 (20176)   Saving time: 00:00:04.6771788
   [11.04.2022 00:09:21]   78 (20176)  Saving item: /sites/CYMI/Teste/test
   [11.04.2022 00:13:27]   78 (20176)   Saving time: 00:04:10.742124
   ```
   2. The second saving time (00:04:10.7421244) includes the first saving time (00:00:04.6771788). 
3. Save items to the database with content
   1. Downloading incomplete items - start saving the content of items.
   1. Downloading item content - start content loading. If a backup is interrupted, the position can be different, etag is changing as soon as item content changed.
   1. Starting download of resource - begin downloading.
   1. Download completed - finish downloading.
   1. Display
      1. Download time - the time it takes to download a batch of content in a file.
      1. Saving time - time it takes to save to a database.
4. Mark deleted items
   1. Marks items in DB as deleted, except for the items that were backed up. In other words, this step allows to see what items are removed from production. 
   1. Can have values from 0 to 2147483647.
   1. Only displayed during full backup.
   1. Displays:
      1. For full backup: Marking deleted items: 223213 - 223232...
      1. For incremental: Marking deleted items in the database...
5. Display rates
   1. Total data - the number of items saved to the repository (from Saving Rate).
   1. Receive rate - the number of loaded data (sync requests + requests to save fields + content itself) divided by the summary time for requests.
   1. Saving rate - number of items saved in the repository before the time prior to saving these data.

## Rate calculations
### Log Example
```
[11.04.2022 08:14:07] 91 (1068) Saving time: 00:02:27.8190367
[11.04.2022 08:14:07] 91 (1068) Downloading incomplete items...
[11.04.2022 08:16:41] 91 (1068)  Download completed
[11.04.2022 08:16:41] 91 (1068)   Download time: 6,2238678
[11.04.2022 08:16:41] 91 (1068)   Saving time: 32,9847548
[11.04.2022 08:17:23] 91 (1068) Total data: 10234088
[11.04.2022 08:17:23] 91 (1068) Receive rate: 43189 B/s
[11.04.2022 08:17:23] 91 (1068) Saving rate : 56603 B/s
```

### Calculations

Saving time: 00:02:27.8190367 = 147.8190367 (in seconds)
+
Saving time: 32,9847548
-=-=-=-=-
180,8037915


Total data: 10234088
/
Saving rate : 56603 B/s
-=-=-=-=-
180,8046923307952

**Note**: The above example is displayed for. saving rates/times. To calculate Receive rate, divide

- all loaded data (sync requests + fields requests + content) by
- sum time for all requests.
As opposed to saving, receive functioning operates with time and volume (not only the data that is written to DB, but also the time it takes to serve requests to fetch data and its volume).

These operations/metrics ("metadata" or "operational") are not logged, thus the above calculations won't be applicable for calculating Receive rate.

## Target vs Source bottleneck
Source bottleneck is reflected in receive rate as well. 

The current bottleneck doesn't affect rate calculations.

## Total data explanation
### Non-zero
If the Total data is not zero, marking items for deletion usually takes more than 30 seconds for the following reason: 

- During full backup request items from the production according to their ID number (in sequence).
- Take a batch of items, backing up the first and that latest ID (smallest and largest) - this is our range.
- Remember what IDs are in that range.
- Go to a database and find items in it with all IDs from that range. 
- Find what items exist, what items are not marked as deleted and check whether they are  a part of that batch that we worked with.
- If not, it means that the item doesn't exist on the production server and it is marked as removed.
### Zero
Total data equal to zero means that there was no new data written to the repository (number of saved items = 0).


### Sync time investigation
When troubleshooting SPO performance note Sync time. If it's too big, see why sync items are too big. It could be that

- there are just too many item versions;
- it is related to the VBO infrastructure e.g. between VBO and cloud part;
- etc.
Check log files and see what lists are processing with the Full Backup type. 
​​
## Build rate statistics for performance related cases
To provide greater visibility for Veeam Backup for Microsoft 365 customers, the support team engineer should be able to collect receive rate / saving rate statistics for any performance-related issue. This information can also be used to engage the RND team and complete the data set. 
1. (optionally) Ask the customer to wait for the backup job to finish.
2. Collect backup job logs. Try to run the only troublesome backup job at a time so that it doesn't interfere with another "more performant" backup job. 
3. Open logs bundle in the text editor of your choice. using Visual Studio Code as an example below.
4. Find the maximum "Receive rate" to know what is the limit of downloading items from the cloud.
   - Enable **regex search**
   - Search for `Receive rate: [0-9]* B/s` and save this number as the total amount of receive operations `t`
   - Search for `Receive rate: [0-9]{n} B/s` where `n` is a number of repeats for any digit used before
   - Start with some maximum value and decrease it until you hit some search results. Let's call this digit `p`. 
   - Once you know the number of digits for receive rate, change the search query to `Receive rate: q[0-9]{m} B/s` where `q` is 9 and `m` is `p - 1`. 
   - If there are no results decrement `q` until you hit search results 
   - Visually (the search results number should be not significant at this point) or by repeating the same steps above find the maximum Receive rate
   - Translate from B/s to MB/s and capture this value
5. Using the same procedure as on step 4, build a "Receive rate" distribution
   - Find how many search results appear when searching for `n-1`
   - Find how many search results appear when searching for `q[0-9]{n-2}`. Continue decrementing `q` 
   - Write down all distribution results in some similar to the below fashion: 
   ```
   Maximum Receive rate: 3.4 MB / s
   More than 4 MB / s received in just 107 downloads out of 8461 times
   2,145 downloads the data set at a speed of 3 MB - 4 MB
   3534 times downloaded the data set at a speed of 2 MB - 3 MB
   1744 downloads the data set at a speed of 1 MB - 2 MB
   843 times downloaded the data set at less than 1 MB
   ```

6. Build the same distribution for "Saving rate". 

**Note:** "Saving rate" has a blank space before column, unlike "Receive rate", e.g. `Saving rate : 2517033 B/s`

The expected outcome is presented below:
```Maximum Receive rate: 3.4 MB / s
More than 4 MB / s received in just 107 downloads out of 8461 times
2,145 downloads the data set at a speed of 3 MB - 4 MB
3534 times downloaded the data set at a speed of 2 MB - 3 MB
1744 downloads the data set at a speed of 1 MB - 2 MB
843 times downloaded the data set at less than 1 MB

Maximum Saving rate: 147 MB / s (10/30/2021 4:02:38 AM 254 (2164) Saving rate: 147 080 598 B / s)
3 times saved to disk at 80+ MB / s out of 8461 times
6 times saved to disk at 70 - 80 MB / s
17 times saved to disk at 60 - 70 MB / s
35 times saved to disk at 50 - 60 MB / s
1882 times saved to disk at 10 - 50 MB / s
Save 434 times to disk at less than 10
```