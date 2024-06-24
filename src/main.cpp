#include <crow_all.h>
#include <algorithm>
#include <fstream>
#include <unistd.h>

using namespace std;


int main()
{
    crow::SimpleApp app;

    CROW_ROUTE (app, "/") ([] () {
        auto page = crow::mustache::load("page.html");
		crow::mustache::context ctx;
		
		ifstream facts_file;
		facts_file.open("assets/facts.html");

		string tmp;
		vector<string> lines;
		while (getline(facts_file, tmp)) {
			lines.push_back(tmp);
		}
		facts_file.close();

		ctx["facts"] = lines;

		lines.clear();

		ifstream posts_file;
		posts_file.open("assets/posts.html");

		while (getline(posts_file, tmp)) {
			lines.push_back(tmp);
		}

		auto latest_post_begin = find(lines.rbegin(), lines.rend(), "===START=OF=POST===") - 1;
		
		string latest_post_text;

		for (; latest_post_begin > lines.rbegin(); latest_post_begin--) {
			latest_post_text += (*latest_post_begin) += "<br>";
		}

		latest_post_text.erase(latest_post_text.end() - 4, latest_post_text.end());

		posts_file.close();

		ctx["latest_post"] = latest_post_text;

		return page.render(ctx);
    });

    CROW_ROUTE (app, "/blog") ([] () {
        auto page = crow::mustache::load("blog.html");
		crow::mustache::context ctx;
		
		vector<string> lines;
		string tmp;

		ifstream posts_file;
		posts_file.open("assets/posts.html");

		while (getline(posts_file, tmp)) {
			lines.push_back(tmp);
		}

		posts_file.close();
		
		vector<string> posts;

		for (int i = 0; i < lines.size(); i++) {
			if (lines[i] == "===START=OF=POST===") {
				i++;
				string tmp = "";
				string text = "";
				tmp = lines[i];
				while (tmp != "===END=OF=POST===") {
					text += tmp + "<br>";
					i++;
					tmp = lines[i];
				}
				text.erase(text.end() - 4, text.end());
				posts.push_back(text);
			}
		}

		vector<string> reversed_posts(posts.rbegin(), posts.rend());

		ctx["posts"] = reversed_posts;

		return page.render(ctx);
    });

	CROW_ROUTE (app, "/add_post/") ([] (const crow::request& req) {
		string myauth = req.get_header_value("Authorization");
		string mycreds = myauth.substr(6);
		string d_mycreds = crow::utility::base64decode(mycreds, mycreds.size());
		size_t found = d_mycreds.find(':');
		string username = d_mycreds.substr(0, found);
		string password = d_mycreds.substr(found+1);
		if (username == getenv("ADMIN_USERNAME") && password == getenv("ADMIN_PASSWORD")) {

			string text = req.get_header_value("Text");
			
			ofstream file;
			file.open("assets/posts.html", ios::app);

			file << "===START=OF=POST===\n";
			file << text << '\n';
			file << "===END=OF=POST===\n";
			
			file.close();

			return 200;
		}

		return 402;
	});
    app.port(8005).run();
}
