-- GSoC 2013 - Communicating with mobile devices.
{-# LANGUAGE FlexibleContexts #-}
-- | This Module define the main data types for sending Push Notifications through Google Cloud Messaging.
module PushNotify.Gcm.Types
    ( GCMAppConfig(..)
    , GCMmessage(..)
    , GCMresult(..)
    , RegId
    ) where


import PushNotify.Gcm.Constants
import Data.Default
import Data.Aeson.Types
import Data.Text
import Data.Monoid
import Control.Monad.Writer


-- | 'GCMAppConfig' represents the main necessary information for sending notifications through GCM.
data GCMAppConfig = GCMAppConfig
    {   apiKey   :: Text
    ,   senderID :: Text
    ,   numRet   :: Int
    }   deriving Show


type RegId = Text


-- | 'GCMmessage' represents a message to be sent through GCM.
data GCMmessage = GCMmessage
    {   registration_ids        :: [RegId]
    ,   collapse_key            :: Maybe Text
    ,   data_object             :: Maybe Object
    ,   delay_while_idle        :: Bool
    ,   time_to_live            :: Maybe Int
    ,   restricted_package_name :: Maybe Text
    ,   dry_run                 :: Bool
    } deriving Show

instance Default GCMmessage where
    def = GCMmessage {
        registration_ids        = []
    ,   collapse_key            = Nothing
    ,   data_object             = Nothing
    ,   delay_while_idle        = False
    ,   time_to_live            = Nothing
    ,   restricted_package_name = Nothing
    ,   dry_run                 = False
    }


-- | 'GCMresult' represents information about messages after a communication with GCM Servers.
data GCMresult = GCMresult
    {   multicast_id      :: Maybe Integer
    ,   success           :: Maybe Int
    ,   failure           :: Maybe Int
    ,   canonical_ids     :: Maybe Int
    ,   newRegids         :: [(RegId,RegId)] -- ^ regIds that need to be replaced.
    ,   messagesIds       :: [(RegId,Text)] -- ^ Successful RegIds, and its message_id
    ,   errorUnRegistered :: [RegId] -- ^ Failed regIds that need to be removed.
    ,   errorToReSend     :: [RegId] -- ^ Failed regIds that I need to resend the message to,
                                     -- ^ because there was an internal problem in the GCM servers.
    ,   errorRest         :: [(RegId,Text)] -- ^ Failed regIds with the rest of the possible errors (probably a non-recoverable errors)
    } deriving Show

instance Default GCMresult where
    def = GCMresult {
        multicast_id      = Nothing
    ,   success           = Nothing
    ,   failure           = Nothing
    ,   canonical_ids     = Nothing
    ,   newRegids         = []
    ,   messagesIds       = []
    ,   errorUnRegistered = []
    ,   errorToReSend     = []
    ,   errorRest         = []
    }

instance Monoid GCMresult where
    mempty = def
    mappend (GCMresult _ x1 y1 z1 a1 b1 c1 d1 e1) (GCMresult _ x2 y2 z2 a2 b2 c2 d2 e2) = 
                        GCMresult Nothing (add x1 x2) (add y1 y2) (add z1 z2) (a1 ++ a2) (b1 ++ b2) (c1 ++ c2) (d1 ++ d2) (e1 ++ e2)
                        where 
                              add x Nothing = x
                              add (Just n) (Just m) = Just (n+m)
                              add (Nothing) (Just m) = Just m

ifNotDef :: (ToJSON a,MonadWriter [Pair] m,Eq a)
            => Text
            -> (GCMmessage -> a)
            -> GCMmessage
            -> m ()
ifNotDef label f msg = if f def /= f msg
                        then tell [(label .= (f msg))]
                        else tell []

instance ToJSON GCMmessage where
    toJSON msg = object $ execWriter $ do
                                         ifNotDef cREGISTRATION_IDS registration_ids msg
                                         ifNotDef cTIME_TO_LIVE time_to_live msg
                                         ifNotDef cDATA data_object msg
                                         ifNotDef cCOLLAPSE_KEY collapse_key msg
                                         ifNotDef cRESTRICTED_PACKAGE_NAME restricted_package_name msg
                                         ifNotDef cDELAY_WHILE_IDLE delay_while_idle msg
                                         ifNotDef cDRY_RUN dry_run msg
