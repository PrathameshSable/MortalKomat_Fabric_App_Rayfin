import * as THREE from "three";

/** Convert lat/lon (degrees) to a point on a sphere of the given radius. */
export function latLonToVector3(
  lat: number,
  lon: number,
  radius: number,
  target = new THREE.Vector3(),
): THREE.Vector3 {
  const phi = (90 - lat) * (Math.PI / 180);
  const theta = (lon + 180) * (Math.PI / 180);
  target.set(
    -radius * Math.sin(phi) * Math.cos(theta),
    radius * Math.cos(phi),
    radius * Math.sin(phi) * Math.sin(theta),
  );
  return target;
}

/** A cool→hot color ramp by normalized altitude (0..1), as an RGB triple. */
export function altitudeColor(altMeters: number | null): [number, number, number] {
  const t = Math.max(0, Math.min(1, (altMeters ?? 0) / 13000));
  // teal (low) → amber (mid) → magenta (high)
  const c = new THREE.Color();
  c.setHSL(0.55 - 0.45 * t, 0.85, 0.55);
  return [c.r, c.g, c.b];
}
