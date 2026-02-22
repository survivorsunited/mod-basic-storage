package com.khazoda.basicstorage.util;

import java.lang.reflect.Method;
import net.minecraft.entity.Entity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;
import net.minecraft.world.RaycastContext;
import net.minecraft.world.World;

public class BlockUtils {

  /** Works on both 1.21.8 (getWorld) and 1.21.9+ (getEntityWorld). */
  public static World getWorld(Entity entity) {
    try {
      Method m = Entity.class.getMethod("getEntityWorld");
      return (World) m.invoke(entity);
    } catch (NoSuchMethodException e) {
      try {
        Method m = Entity.class.getMethod("getWorld");
        return (World) m.invoke(entity);
      } catch (Exception ex) {
        throw new RuntimeException("Could not get world from entity", ex);
      }
    } catch (Exception e) {
      throw new RuntimeException("Could not get world from entity", e);
    }
  }

  public static BlockHitResult getHitResult(PlayerEntity player, BlockPos target) {
    final Vec3d castOrigin = player.getEyePos();
    final double castLength = Vec3d.ofCenter(target).subtract(castOrigin).length() + 1;
    final Vec3d playerRotation = player.getRotationVector();
    final Vec3d castTarget = castOrigin.add(playerRotation.multiply(castLength));
    
    return getWorld(player).raycast(new RaycastContext(castOrigin, castTarget, RaycastContext.ShapeType.OUTLINE, RaycastContext.FluidHandling.NONE, player));
  }

  public static int getComparatorOutputStrength(int itemStackCount) {
    return MathHelper.floor(itemStackCount % 16);
  }

  /** Works on both 1.21.8 (isClient field) and 1.21.9+ (isClient() method). */
  public static boolean isClient(net.minecraft.world.World world) {
    if (world == null) return false;
    try {
      java.lang.reflect.Method m = net.minecraft.world.World.class.getMethod("isClient");
      return Boolean.TRUE.equals(m.invoke(world));
    } catch (NoSuchMethodException e) {
      try {
        java.lang.reflect.Field f = net.minecraft.world.World.class.getField("isClient");
        return Boolean.TRUE.equals(f.getBoolean(world));
      } catch (Exception ex) {
        throw new RuntimeException("Could not get isClient from world", ex);
      }
    } catch (Exception e) {
      throw new RuntimeException("Could not get isClient from world", e);
    }
  }
}
