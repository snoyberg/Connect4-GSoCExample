{-# LANGUAGE OverloadedStrings, TypeFamilies, TemplateHaskell, QuasiQuotes, FlexibleContexts, GADTs #-}
             
module DataBase where

import Yesod
import Data.Text
import PushNotify.General
import Extra
import Connect4

-- Data Base:

share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
Devices
    user Text
    password Text
    identifier Identifier
    UniqueUser user
    UniqueDevice identifier
    deriving Show
Games
    user1  Text
    user2  Text
    turn   Text
    matrix Board
    UniqueUser1 user1
    UniqueUser2 user2
|]
