module Ircbrowse.Model.Stats where

import Ircbrowse.Types

import Data.Maybe
import Snap.App

getStats :: Maybe String -> Maybe String -> Range -> Model c s Stats
getStats network channel (Range from to) = do
  count <- single ["SELECT COUNT(*)"
                  ,"FROM event"
                  ,"WHERE timestamp > ? and timestamp < ?"]
                  (from,to)
  msgcount <- single ["SELECT COUNT(*)"
                     ,"FROM event"
                     ,"WHERE type = 'talk'"
                     ,"AND timestamp > ? and timestamp < ?"]
                     (from,to)
  nicks <- single ["SELECT COUNT(DISTINCT nick)"
                  ,"FROM event"
                  ,"WHERE type = 'talk'"
                  ,"AND timestamp > ? and timestamp < ?"]
                  (from,to)
  activetimes <- query ["SELECT DATE_PART('HOUR',timestamp)::int,COUNT(*)"
                       ,"FROM EVENT"
                       ,"WHERE type = 'talk'"
                       ,"AND timestamp > ? AND timestamp < ?"
                       ,"GROUP BY DATE_PART('HOUR',timestamp)"
                       ,"ORDER BY 1 ASC"]
                       (from,to)
  dailyactivity <- query ["SELECT date_part('day',date)::int,count FROM"
                         ," (SELECT timestamp::date as date,COUNT(*) as count"
                         ,"  FROM EVENT"
                         ,"  WHERE type = 'talk'"
                         ,"  AND timestamp > ? AND timestamp < ?"
                         ,"  GROUP BY timestamp::date"
                         ,"  ORDER BY 1 ASC) c"]
                         (from,to)
  activenicks <- query ["SELECT nick,COUNT(*)"
                       ,"FROM EVENT"
                       ,"WHERE type = 'talk'"
                       ,"AND timestamp > ?"
                       ,"AND timestamp < ?"
                       ,"GROUP BY nick"
                       ,"ORDER BY 2 DESC"
                       ,"LIMIT 50"]
                       (from,to)
  networks <- queryNoParams ["SELECT name,title FROM network order by title"]
  channels <- queryNoParams ["SELECT network,name FROM channel order by name"]
  return Stats
    { stEventCount = fromMaybe 0 count
    , stMsgCount = fromMaybe 0 msgcount
    , stNickCount = fromMaybe 0 nicks
    , stActiveTimes = activetimes
    , stDailyAcitivty = dailyactivity
    , stActiveNicks = activenicks
    , stNetworks = networks
    , stChannels = channels
    }
