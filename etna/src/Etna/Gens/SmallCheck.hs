{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Etna.Gens.SmallCheck where

import qualified Test.SmallCheck.Series as SC

import Etna.Properties (RibbonArgs(..), FuseArgs(..), AlterAnnArgs(..), RtwArgs(..))

-- The page-width parameter for the ribbon variant ranges 1..20.
-- SmallCheck enumerates by depth; we expose the values directly.
series_ribbon_width_floor :: Monad m => SC.Series m RibbonArgs
series_ribbon_width_floor =
  RibbonArgs <$> SC.generate (\d -> [1 .. min (d + 2) 20])

series_fuse_annotated_docs :: Monad m => SC.Series m FuseArgs
series_fuse_annotated_docs =
  FuseArgs <$> SC.generate (\_ -> ['A', 'B', 'Z'])

series_alter_annotations_balanced :: Monad m => SC.Series m AlterAnnArgs
series_alter_annotations_balanced =
  AlterAnnArgs <$> SC.generate (\_ -> ['A', 'B', 'Z'])

series_rtw_indent_blank_lines :: Monad m => SC.Series m RtwArgs
series_rtw_indent_blank_lines = do
  i1 <- SC.generate (\d -> [0 .. min (d + 1) 4])
  i2 <- SC.generate (\d -> [0 .. min (d + 1) 4])
  pure (RtwArgs i1 i2)
