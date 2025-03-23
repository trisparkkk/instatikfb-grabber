import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { join, parse } from "node:path";
import { cwd } from "node:process";

const findFile = (file) => {
	let dir = cwd();

	while (dir !== parse(dir).root) {
		if (existsSync(join(dir, file))) {
			return dir;
		}

		dir = join(dir, "../");
	}
};

const root = findFile(".git");
const pack = findFile("package.json");

const readGit = async (filename) => {
	if (!root) {
		// Try to read from the static files first
		const staticFile = filename.replace(".git/", "git_");
		try {
			return await readFile(join(cwd(), staticFile), "utf8");
		} catch {
			throw "no git repository root found";
		}
	}

	return readFile(join(root, filename), "utf8");
};

export const getCommit = async () => {
	return (
		(await readGit(".git/logs/HEAD"))?.split("\n")?.filter(String)?.pop()?.split(" ")[1] ||
		(await readGit(".git/commit"))?.trim()
	);
};

export const getBranch = async () => {
	if (process.env.CF_PAGES_BRANCH) {
		return process.env.CF_PAGES_BRANCH;
	}

	try {
		const gitHead = await readGit(".git/HEAD");
		return gitHead?.replace(/^ref: refs\/heads\//, "")?.trim();
	} catch {
		return (await readGit(".git/branch"))?.trim();
	}
};

export const getRemote = async () => {
	let remote;
	try {
		remote = (await readGit(".git/config"))
			?.split("\n")
			?.find((line) => line.includes("url = "))
			?.split("url = ")[1];
	} catch {
		remote = await readGit(".git/remote");
	}

	if (remote?.startsWith("git@")) {
		remote = remote.split(":")[1];
	} else if (remote?.startsWith("http")) {
		remote = new URL(remote).pathname.substring(1);
	}

	remote = remote?.replace(/\.git$/, "")?.trim();

	if (!remote) {
		throw "could not parse remote";
	}

	return remote;
};

export const getVersion = async () => {
	if (!pack) {
		throw "no package root found";
	}

	const { version } = JSON.parse(await readFile(join(pack, "package.json"), "utf8"));

	return version;
};
