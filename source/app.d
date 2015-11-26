import std.stdio;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import std.exception;
import std.random;
import std.range;
import std.math;
import std.getopt;

SDL_Window* window;
SDL_Renderer* render;

struct Picture {
	SDL_Texture* tex;
	int x;
	int y;
	void renderAt(int rx, int ry) {
		auto rect = SDL_Rect(rx - x / 2, ry - y / 2, (x + 1) / 2, (y + 1) / 2);
		SDL_RenderCopy(render, tex, null, &rect);
	}
}

auto loadTexture(const char* name) {
	auto bit = IMG_Load(name);
	if (!bit) {
		auto err = IMG_GetError();
		import std.c.string;

		writeln(err[0 .. strlen(err)]);
		enforce(0);
	}
	auto ret = Picture(SDL_CreateTextureFromSurface(render, bit), bit.w, bit.h);
	SDL_FreeSurface(bit);
	return ret;
}

Universe env;

struct Universe {
	GravityObj[] objs;
}

struct GravityObj {
	real x;
	real y;
	real xvel;
	real yvel;
	Picture pic;
}

void main(string[] args) {
	DerelictSDL2.load();
	DerelictSDL2Image.load();
	SDL_Init(SDL_INIT_VIDEO);
	IMG_Init(IMG_INIT_PNG);
	int w = 640;
	int h = 480;
	int d = 10;
	bool help;
	getopt(args, "w|width", &w, "h|height", &h, "d|delay", &d, "help", &help);
	if (help) {
		writeln(args[0] ~ '\n', "--width=\n--height=\n--delay");
		return;
	}
	SDL_CreateWindowAndRenderer(w, h, 0, &window, &render);
	auto texture = loadTexture("obj.png".ptr);
	foreach (i; 0 .. 128) {
		env.objs ~= GravityObj(uniform(0.0, w), uniform(0.0, h), uniform(-.1,
			.1), uniform(-.1, .1), texture);
	}
	SDL_Event e;
	while (true) {
		auto time = SDL_GetTicks();
		while (SDL_PollEvent(&e)) {
			switch (e.type) {
			case SDL_QUIT:
				return;
			default:
			}
		}
		foreach (c, ref obj; env.objs) {
			obj.x += obj.xvel;
			obj.y += obj.yvel;
			obj.x %= w;
			obj.x += obj.x < 0 ? 640 : 0;
			obj.y %= h;
			obj.y += obj.y < 0 ? 480 : 0;
		}
		foreach (c, ref obj; env.objs) {
			auto others = env.objs[0 .. c].chain(env.objs[c + 1 .. $]);
			foreach (other; others) {
				auto xdiff = other.x - obj.x;
				auto ydiff = other.y - obj.y;
				auto angle = atan2(ydiff, xdiff);
				if ((xdiff ^^ 2 + ydiff ^^ 2).sqrt > 8) {
					auto force = 1 / (xdiff ^^ 2 + ydiff ^^ 2);
					obj.xvel += force * cos(angle);
					obj.yvel += force * sin(angle);
				}
			}
		}

		SDL_RenderClear(render);
		foreach (obj; env.objs) {
			obj.pic.renderAt(cast(int) obj.x, cast(int) obj.y);
		}
		SDL_RenderPresent(render);
		auto net = SDL_GetTicks() - time;
		if (d > net) {
			SDL_Delay(d - net);
		}
	}
}
