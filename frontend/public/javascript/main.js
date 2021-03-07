let posts = [
  {
    content: "This is Carl's post",
    username: "Carl",
    comments: [
      {
        username: 'Graham',
        comment: 'This is a cool post!'
      }
    ]
  },
  {
    content: "This is Graham's post",
    username: "Graham",
    comments: [
      {
        username: 'Carl',
        comment: 'This is an even cooler post!'
      },
      {
        username: 'Chris Lee',
        comment: 'You guys should apply for Summer Capstone ;)'
      },
    ]
  },
]

let postsTemplate  = Handlebars.compile($('#posts').html());

Handlebars.registerPartial('post', $('#post').html());
Handlebars.registerPartial('comment', $('#comment').html());

$('div.container').append(postsTemplate({ posts: posts }));