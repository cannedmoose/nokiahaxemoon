import openfl.display.Shader;
import openfl.display.DisplayObjectShader;

/**
	Fragment shader for restricting colours to nokia legal ones.
**/
class NokiaShader extends DisplayObjectShader {
	@:glFragmentSource("
	#pragma header
	float luma(vec4 color) {
		return dot(color.rgb, vec3(0.299, 0.587, 0.114));
	}
	void main(void) {
		#pragma body
		 vec4 color2 = texture2D (openfl_Texture, openfl_TextureCoordv);
		 // If alpha is small, just remove alpha and let BG through.
		 if (color2.a < .45) {
			 gl_FragColor = vec4(0, 0 , 0 ,0);
		 } else if (luma(color2) < .3) {
			 gl_FragColor = vec4(0.263, 0.322, 0.239, 1.0) ;
		 } else {
			 gl_FragColor = vec4(0.78, 0.941, 0.847, 1.0);
		 }
	}
	")
	public function new() {
		super();
	}
}

/**
	Fragment shader for converting grayscale perlin noise to clouds.
**/
class CloudShader extends Shader {
	@:glFragmentSource("
	#pragma header
	uniform float cutoff;
	uniform vec2 lightMul;
	float luma(vec4 color) {
		return dot(color.rgb, vec3(0.299, 0.587, 0.114));
	}

	int neighbourEmpty(vec2 pos) {
		vec2 onePixel = lightMul / openfl_TextureSize;
		vec4 c = texture2D (openfl_Texture, openfl_TextureCoordv + (onePixel*pos));
		if (luma(c) > cutoff){return 1;}
		else {return 0;};
	}

	void main(void) {
		#pragma body
		 vec4 pixel = texture2D (openfl_Texture, openfl_TextureCoordv);
		 int emptyNeighbours = neighbourEmpty(vec2(-1, -1)) 
			 + neighbourEmpty(vec2(0, -1))
			 + neighbourEmpty(vec2(1, -1))
			 + neighbourEmpty(vec2(-1, 0))
			 + neighbourEmpty(vec2(-1, 1))
			 + neighbourEmpty(vec2(1, 0))
			 + neighbourEmpty(vec2(0, 1))
			 + neighbourEmpty(vec2(1, 1));
		
			if ( luma(pixel) < cutoff) {
			 if (emptyNeighbours > 2) {
				 gl_FragColor = vec4(0.78, 0.941, 0.847, 1);
			 } else {
				 gl_FragColor = vec4(0.263, 0.322, 0.239, 1);
			 }
		 } else {
			gl_FragColor = vec4(0, 0, 0, 0);
		 }
	}
	")
	public function new() {
		super();
	}
}
