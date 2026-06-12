import { useRef } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import { OrbitControls, Stars, Billboard } from "@react-three/drei";
import * as THREE from "three";
import type { Flight } from "../data/types.js";
import { latLonToVector3 } from "../lib/geo.js";
import { Globe, GLOBE_RADIUS } from "./Globe.js";
import { Aircraft } from "./Aircraft.js";

interface SceneProps {
  getFlights: () => Flight[];
  advance: (dt: number) => void;
  planeSize: number;
  speed: number;
  autoRotate: boolean;
  selected: Flight | null;
  onSelect: (flight: Flight) => void;
  onClearSelection: () => void;
}

/** A pulsing ring that marks the currently selected aircraft. */
function SelectionMarker({ flight }: { flight: Flight }) {
  const ref = useRef<THREE.Mesh>(null);
  const pos = latLonToVector3(flight.latitude, flight.longitude, GLOBE_RADIUS * 1.02);
  useFrame(({ clock }) => {
    if (ref.current) {
      const s = 1 + Math.sin(clock.elapsedTime * 4) * 0.15;
      ref.current.scale.setScalar(s);
    }
  });
  return (
    <Billboard position={[pos.x, pos.y, pos.z]}>
      <mesh ref={ref}>
        <ringGeometry args={[0.045, 0.07, 32]} />
        <meshBasicMaterial color="#ffd166" transparent opacity={0.9} side={THREE.DoubleSide} />
      </mesh>
    </Billboard>
  );
}

export function Scene(props: SceneProps) {
  const {
    getFlights, advance, planeSize, speed, autoRotate, selected, onSelect, onClearSelection,
  } = props;

  return (
    <Canvas
      camera={{ position: [0, 1.6, 6], fov: 45 }}
      dpr={[1, 2]}
      raycaster={{ params: { Points: { threshold: 0.04 } } as THREE.RaycasterParameters }}
      onPointerMissed={onClearSelection}
      gl={{ antialias: true }}
    >
      <color attach="background" args={["#03060f"]} />
      <ambientLight intensity={0.6} />
      <directionalLight position={[5, 3, 5]} intensity={1.4} color="#fff6e8" />
      <Stars radius={120} depth={60} count={6000} factor={4} saturation={0} fade speed={0.6} />

      <Globe />
      <Aircraft
        getFlights={getFlights}
        advance={advance}
        size={planeSize}
        speed={speed}
        onSelect={onSelect}
      />
      {selected && <SelectionMarker flight={selected} />}

      <OrbitControls
        enablePan={false}
        autoRotate={autoRotate}
        autoRotateSpeed={0.35}
        minDistance={3.2}
        maxDistance={12}
        rotateSpeed={0.5}
      />
    </Canvas>
  );
}
