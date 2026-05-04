{-# LANGUAGE DefaultSignatures #-}
module Fields where

import Imports
import GHC.Generics
import Data.Text qualified as T

formatFields :: Fields -> [Text]
formatFields = map \ case
  (name, value) -> T.intercalate "." name <> ": " <> value

type Fields = [([Text], Text)]

leaf :: Text -> Fields
leaf value = [([], value)]

class ToFields a where
  toFields :: a -> Fields
  default toFields :: (Generic a, GenericToFields (Rep a)) => a -> Fields
  toFields = genericToFields . from

instance ToFields Int where
  toFields = leaf . show

instance ToFields Text where
  toFields = leaf

instance ToFields a => ToFields (Maybe a) where
  toFields = \ case
    Nothing -> leaf "unknown"
    Just value -> toFields value

labelWith :: String -> Fields -> Fields
labelWith = map . first . (:) . pack

class GenericToFields f where
  genericToFields :: f a -> Fields

instance (GenericToFields f) => GenericToFields (M1 D d f) where
  genericToFields = genericToFields . unM1

instance (GenericToFields f) => GenericToFields (M1 C c f) where
  genericToFields = genericToFields . unM1

instance (GenericToFields a, GenericToFields b) => GenericToFields (a :*: b) where
  genericToFields (a :*: b) = genericToFields a <> genericToFields b

instance (Selector s, GenericToFields f) => GenericToFields (M1 S s f) where
  genericToFields metadata@(M1 selector) = labelWith (selName metadata) $ genericToFields selector

instance ToFields a => GenericToFields (K1 i a) where
  genericToFields (K1 value) = toFields value
