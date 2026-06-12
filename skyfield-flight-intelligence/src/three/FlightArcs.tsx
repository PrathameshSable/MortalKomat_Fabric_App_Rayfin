import { useMemo, useRef } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import type { Flight } from "../data/types.js";
import { altitudeColor } from "../lib/geo.js";
import { forwardArc } from "../lib/greatCircle.js";
import { GLOBE_RADIUS } from "./Globe.js";

const MAX_ARCS = 600;
const STEPS = 14;
const SURFACE = GLOBE_RADIUS * 1.012;
// Each arc contributes STEPS segments → STEPS*2 vertices.
const MAX_VERTS = MAX_ARCS * STEPS * 2;

interface FlightArcsProps {
  getFlights: () => Flight[];
  filterFn?: (f: Flight) => boolean;
}

/**
 * Glowing forward great-circle trajectories — a "comet tail" ahead of each
 * aircraft, colored by altitude and fading toward the tip. Rebuilt a few times
 * a second (not every frame) so it follows motion without tanking the GPU.
 */
export function FlightArcs({ getFlights, filterFn }: FlightArcsProps) {
  const acc = useRef(0);

  const segments = useMemo(() => {
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute("position", new THREE.BufferAttribute(new Float32Array(MAX_VERTS * 3), 3));
    geometry.setAttribute("color", new THREE.BufferAttribute(new Float32Array(MAX_VERTS * 3), 3));
    const material = new THREE.LineBasicMaterial({
      vertexColors: true,
      transparent: true,
      opacity: 0.7,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
    });
    return new THREE.LineSegments(geometry, material);
  }, []);

  const rebuild = () => {
    const all = getFlights();
    const flights = filterFn ? all.filter(filterFn) : all;
    const pos = segments.geometry.attributes.position as THREE.BufferAttribute;
    const col = segments.geometry.attributes.color as THREE.BufferAttribute;
    const posArr = pos.array as Float32Array;
    const colArr = col.array as Float32Array;

    let v = 0;
    const count = Math.min(flights.length, MAX_ARCS);
    for (let i = 0; i < count; i++) {
      const f = flights[i]!;
      if (f.onGround || f.heading == null) continue;
      const arc = forwardArc(f.latitude, f.longitude, f.heading, SURFACE, { steps: STEPS });
      const [r, g, b] = altitudeColor(f.geoAltitude);
      for (let s = 0; s < arc.length - 1; s++) {
        const a = arc[s]!;
        const b2 = arc[s + 1]!;
        // Fade toward the tip for a comet look.
        const f0 = 1 - s / arc.length;
        const f1 = 1 - (s + 1) / arc.length;
        posArr[v * 3] = a.x; posArr[v * 3 + 1] = a.y; posArr[v * 3 + 2] = a.z;
        colArr[v * 3] = r * f0; colArr[v * 3 + 1] = g * f0; colArr[v * 3 + 2] = b * f0;
        v++;
        posArr[v * 3] = b2.x; posArr[v * 3 + 1] = b2.y; posArr[v * 3 + 2] = b2.z;
        colArr[v * 3] = r * f1; colArr[v * 3 + 1] = g * f1; colArr[v * 3 + 2] = b * f1;
        v++;
      }
    }
    pos.needsUpdate = true;
    col.needsUpdate = true;
    segments.geometry.setDrawRange(0, v);
  };

  useFrame((_, delta) => {
    acc.current += delta;
    if (acc.current >= 0.4) {
      acc.current = 0;
      rebuild();
    }
  });

  return <primitive object={segments} />;
}
