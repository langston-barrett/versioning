-- | JSON-specific deserialization utilities.
{-# LANGUAGE AllowAmbiguousTypes   #-}
{-# LANGUAGE ConstraintKinds       #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeApplications      #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE TypeInType            #-}
{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE UndecidableInstances  #-}
module Versioning.JSON
  ( Applied
  , JsonDecodableTo
  , fromJsonAnyVersion
  , fromJsonAnyVersionStrict
  , fromJsonAnyVersionEither
  , fromJsonAnyVersionEitherStrict
  , withJsonAnyVersion
  , withJsonAnyVersionStrict
  , withJsonAnyVersionEither
  , withJsonAnyVersionEitherStrict
  , withJsonAnyVersionM
  , withJsonAnyVersionStrictM
  , withJsonAnyVersionEitherM
  , withJsonAnyVersionEitherStrictM
  )
where

import           Data.Aeson                   (FromJSON, decode, decodeStrict,
                                               eitherDecode, eitherDecodeStrict)
import qualified Data.ByteString              as StrictBS
import qualified Data.ByteString.Lazy         as LazyBS

import           Versioning.Internal.Decoding

-- | Decode a JSON string by trying all the versions decrementally
--   and upgrade the decoded object to the newest version.
fromJsonAnyVersion
  :: forall v a . JsonDecodableTo v a => LazyBS.ByteString -> Maybe (a v)
fromJsonAnyVersion = decodeAnyVersion jsonDecode

-- | Like 'fromJsonAnyVersion' but it reads from a strict 'ByteString'
fromJsonAnyVersionStrict
  :: forall v a . JsonDecodableTo v a => StrictBS.ByteString -> Maybe (a v)
fromJsonAnyVersionStrict = decodeAnyVersion jsonDecodeStrict

-- | Like 'fromJsonAnyVersion' but returns a message when decoding fails
fromJsonAnyVersionEither
  :: forall v a
   . JsonDecodableTo v a
  => LazyBS.ByteString
  -> Either String (a v)
fromJsonAnyVersionEither = decodeAnyVersion jsonEitherDecode

-- | Like 'fromJsonAnyVersionStrict' but returns a message when decoding fails
fromJsonAnyVersionEitherStrict
  :: forall v a
   . JsonDecodableTo v a
  => StrictBS.ByteString
  -> Either String (a v)
fromJsonAnyVersionEitherStrict = decodeAnyVersion jsonEitherDecodeStrict

-- | Decode a JSON string by trying all the versions decrementally
--   and apply an action to the decoded object at its original version.
withJsonAnyVersionM
  :: forall c a v m
   . (WithAnyVersion v a c FromJSON, Applicative m, c (a v))
  => ApplyM m a c
  -> LazyBS.ByteString
  -> m (Maybe (Applied c a))
withJsonAnyVersionM = withAnyVersionM @v @c @a jsonDecode

-- | Like 'withJsonAnyVersionM' but it reads from a strict 'ByteString'
withJsonAnyVersionStrictM
  :: forall c a v m
   . (WithAnyVersion v a c FromJSON, Applicative m, c (a v))
  => ApplyM m a c
  -> StrictBS.ByteString
  -> m (Maybe (Applied c a))
withJsonAnyVersionStrictM = withAnyVersionM @v @c @a jsonDecodeStrict

-- | Like 'withJsonAnyVersionM' but returns a message when decoding fails
withJsonAnyVersionEitherM
  :: forall c a v m
   . (WithAnyVersion v a c FromJSON, Applicative m, c (a v))
  => ApplyM m a c
  -> LazyBS.ByteString
  -> m (Either String (Applied c a))
withJsonAnyVersionEitherM = withAnyVersionM @v @c @a jsonEitherDecode

-- | Like 'withJsonAnyVersionStrictM' but returns a message when decoding fails
withJsonAnyVersionEitherStrictM
  :: forall c a v m
   . (WithAnyVersion v a c FromJSON, Applicative m, c (a v))
  => ApplyM m a c
  -> StrictBS.ByteString
  -> m (Either String (Applied c a))
withJsonAnyVersionEitherStrictM = withAnyVersionM @v @c @a jsonEitherDecodeStrict

-- | Decode a JSON string by trying all the versions decrementally
--   and apply a pure function to the decoded object at its original version.
withJsonAnyVersion
  :: forall c a v
   . (WithAnyVersion v a c FromJSON, c (a v))
  => Apply a c
  -> LazyBS.ByteString
  -> Maybe (Applied c a)
withJsonAnyVersion = withAnyVersion @v @c @a jsonDecode

-- | Like 'withJsonAnyVersion' but it reads from a strict 'ByteString'
withJsonAnyVersionStrict
  :: forall c a v
   . (WithAnyVersion v a c FromJSON, c (a v))
  => Apply a c
  -> StrictBS.ByteString
  -> Maybe (Applied c a)
withJsonAnyVersionStrict = withAnyVersion @v @c @a jsonDecodeStrict

-- | Like 'withJsonAnyVersion' but returns a message when decoding fails
withJsonAnyVersionEither
  :: forall c a v
   . (WithAnyVersion v a c FromJSON, c (a v))
  => Apply a c
  -> LazyBS.ByteString
  -> Either String (Applied c a)
withJsonAnyVersionEither = withAnyVersion @v @c @a jsonEitherDecode

-- | Like 'withJsonAnyVersionStrict' but returns a message when decoding fails
withJsonAnyVersionEitherStrict
  :: forall c a v
   . (WithAnyVersion v a c FromJSON, c (a v))
  => Apply a c
  -> StrictBS.ByteString
  -> Either String (Applied c a)
withJsonAnyVersionEitherStrict = withAnyVersion @v @c @a jsonEitherDecodeStrict

-- | Decode with the aeson 'decode' function
jsonDecode :: Decoder FromJSON LazyBS.ByteString Maybe a
jsonDecode = Decoder decode

-- | Decode with the aeson 'decodeStrict' function
jsonDecodeStrict :: Decoder FromJSON StrictBS.ByteString Maybe a
jsonDecodeStrict = Decoder decodeStrict

-- | Decode with the aeson 'eitherDecode' function
jsonEitherDecode :: Decoder FromJSON LazyBS.ByteString (Either String) a
jsonEitherDecode = Decoder eitherDecode

-- | Decode with the aeson 'eitherDecodeStrict' function
jsonEitherDecodeStrict :: Decoder FromJSON StrictBS.ByteString (Either String) a
jsonEitherDecodeStrict = Decoder eitherDecodeStrict

-- | Handy constraint synonym to be used with 'fromJsonAnyVersion'
type JsonDecodableTo v a = DecodableTo FromJSON v a
