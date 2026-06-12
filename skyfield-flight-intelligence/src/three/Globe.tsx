import { useMemo } from "react";
import * as THREE from "three";

export const GLOBE_RADIUS = 2;

/**
 * A stylized Earth: a dark oceanic sphere, a faint lat/lon graticule, and a
 * fresnel atmosphere glow. No external textures required (drop an equirect
 * texture into <Globe textureUrl=.../> later for photoreal). Looks good as-is.
 */
export function Globe({ textureUrl }: { textureUrl?: string }) {
  const earthMap = useMemo(() => {
    if (!textureUrl) return null;
    return new THREE.TextureLoader().load(textureUrl);
  }, [textureUrl]);

  const atmosphereMaterial = useMemo(
    () =>
      new THREE.ShaderMaterial({
        transparent: true,
        side: THREE.BackSide,
        blending: THREE.AdditiveBlending,
        uniforms: { uColor: { value: new THREE.Color("#3aa0ff") } },
        vertexShader: /* glsl */ `
          varying vec3 vNormal;
          void main() {
            vNormal = normalize(normalMatrix * normal);
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: /* glsl */ `
          varying vec3 vNormal;
          uniform vec3 uColor;
          void main() {
            float intensity = pow(0.62 - dot(vNormal, vec3(0.0, 0.0, 1.0)), 3.0);
            gl_FragColor = vec4(uColor, 1.0) * intensity;
          }
        `,
      }),
    [],
  );

  return (
    <group>
      {/* Earth */}
      <mesh>
        <sphereGeometry args={[GLOBE_RADIUS, 64, 64]} />
        {earthMap ? (
          <meshStandardMaterial map={earthMap} metalness={0.1} roughness={0.85} />
        ) : (
          <meshStandardMaterial
            color="#0b2545"
            emissive="#08203a"
            emissiveIntensity={0.5}
            metalness={0.2}
            roughness={0.7}
          />
        )}
      </mesh>

      {/* Graticule */}
      <mesh scale={1.001}>
        <sphereGeometry args={[GLOBE_RADIUS, 36, 18]} />
        <meshBasicMaterial color="#1e5a8a" wireframe transparent opacity={0.25} />
      </mesh>

      {/* Atmosphere glow */}
      <mesh scale={1.18} material={atmosphereMaterial}>
        <sphereGeometry args={[GLOBE_RADIUS, 64, 64]} />
      </mesh>
    </group>
  );
}
