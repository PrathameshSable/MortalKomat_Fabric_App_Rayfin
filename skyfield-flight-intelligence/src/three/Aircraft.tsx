import { useMemo, useRef } from "react";
import { useFrame, type ThreeEvent } from "@react-three/fiber";
import * as THREE from "three";
import type { Flight } from "../data/types.js";
import { altitudeColor, latLonToVector3 } from "../lib/geo.js";
import { GLOBE_RADIUS } from "./Globe.js";

const MAX_POINTS = 8000;
const SURFACE = GLOBE_RADIUS * 1.012;

/** Round, soft sprite so each aircraft reads as a glowing dot. */
function makeSprite(): THREE.Texture {
  const size = 64;
  const canvas = document.createElement("canvas");
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext("2d")!;
  const g = ctx.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
  g.addColorStop(0, "rgba(255,255,255,1)");
  g.addColorStop(0.4, "rgba(255,255,255,0.8)");
  g.addColorStop(1, "rgba(255,255,255,0)");
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, size, size);
  const tex = new THREE.Texture(canvas);
  tex.needsUpdate = true;
  return tex;
}

interface AircraftProps {
  getFlights: () => Flight[];
  advance: (dt: number) => void;
  size: number;
  speed: number;
  filterFn?: (f: Flight) => boolean;
  onSelect: (flight: Flight) => void;
}

export function Aircraft({ getFlights, advance, size, speed, filterFn, onSelect }: AircraftProps) {
  const orderRef = useRef<Flight[]>([]);
  const tmp = useMemo(() => new THREE.Vector3(), []);

  const points = useMemo(() => {
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute("position", new THREE.BufferAttribute(new Float32Array(MAX_POINTS * 3), 3));
    geometry.setAttribute("color", new THREE.BufferAttribute(new Float32Array(MAX_POINTS * 3), 3));
    const material = new THREE.PointsMaterial({
      size,
      map: makeSprite(),
      vertexColors: true,
      transparent: true,
      depthWrite: false,
      sizeAttenuation: true,
      blending: THREE.AdditiveBlending,
    });
    return new THREE.Points(geometry, material);
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  useFrame((_, delta) => {
    advance(Math.min(delta, 0.1) * speed);
    const all = getFlights();
    const flights = filterFn ? all.filter(filterFn) : all;
    orderRef.current = flights;

    const pos = points.geometry.attributes.position as THREE.BufferAttribute;
    const col = points.geometry.attributes.color as THREE.BufferAttribute;
    const posArr = pos.array as Float32Array;
    const colArr = col.array as Float32Array;

    const count = Math.min(flights.length, MAX_POINTS);
    for (let i = 0; i < count; i++) {
      const f = flights[i]!;
      latLonToVector3(f.latitude, f.longitude, SURFACE, tmp);
      posArr[i * 3] = tmp.x;
      posArr[i * 3 + 1] = tmp.y;
      posArr[i * 3 + 2] = tmp.z;
      const [r, g, b] = altitudeColor(f.geoAltitude);
      colArr[i * 3] = r;
      colArr[i * 3 + 1] = g;
      colArr[i * 3 + 2] = b;
    }
    pos.needsUpdate = true;
    col.needsUpdate = true;
    points.geometry.setDrawRange(0, count);
    (points.material as THREE.PointsMaterial).size = size;
  });

  const handleClick = (e: ThreeEvent<MouseEvent>) => {
    e.stopPropagation();
    if (e.index != null) {
      const flight = orderRef.current[e.index];
      if (flight) onSelect(flight);
    }
  };

  return <primitive object={points} onClick={handleClick} />;
}
